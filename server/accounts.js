// Account/authentication API and durable per-user quiz history (Node built-ins only).
const crypto = require('node:crypto');
const fs = require('node:fs/promises');
const path = require('node:path');
const { promisify } = require('node:util');
const questions = require('../assets/flutter_quiz_300.json');

const scrypt = promisify(crypto.scrypt);
const TOKEN_TTL_SECONDS = 60 * 60 * 24 * 30;
const MAX_HISTORY = 100;
const MAX_AUTH_EVENTS = 10000;
const questionBank = new Map(questions.map((question) => [question.id, question]));

class JsonAccountStore {
  constructor(filePath = process.env.DATA_FILE || path.join(__dirname, 'data', 'store.json')) {
    this.filePath = filePath;
    this.data = { users: [], authEvents: [], attempts: {}, sessions: [] };
    this.ready = null;
    this.queue = Promise.resolve();
  }

  async init() {
    if (!this.ready) {
      this.ready = (async () => {
        await fs.mkdir(path.dirname(this.filePath), { recursive: true });
        try {
          const stored = JSON.parse(await fs.readFile(this.filePath, 'utf8'));
          if (!stored || !Array.isArray(stored.users) || !Array.isArray(stored.authEvents) ||
              !stored.attempts || typeof stored.attempts !== 'object' || Array.isArray(stored.attempts) ||
              (stored.sessions !== undefined && !Array.isArray(stored.sessions))) {
            throw new Error('Invalid account store format');
          }
          this.data = { ...stored, sessions: stored.sessions || [] };
        } catch (error) {
          if (error.code !== 'ENOENT') throw error;
          await this._persist(this.data);
        }
      })();
    }
    return this.ready;
  }

  async _persist(data) {
    const tempPath = `${this.filePath}.${process.pid}.${crypto.randomUUID()}.tmp`;
    await fs.writeFile(tempPath, JSON.stringify(data), { encoding: 'utf8', mode: 0o600 });
    await fs.rename(tempPath, this.filePath);
  }

  async read(action) {
    await this.init();
    return action(this.data);
  }

  async mutate(action) {
    const previous = this.queue;
    let release;
    this.queue = new Promise((resolve) => { release = resolve; });
    await previous.catch(() => {});
    try {
      await this.init();
      const result = await action(this.data);
      await this._persist(this.data);
      return result;
    } finally {
      release();
    }
  }
}

function normalizeEmail(value) {
  if (typeof value !== 'string') return null;
  const email = value.trim().toLowerCase();
  if (email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return null;
  return email;
}

function safeStringEqual(left, right) {
  const a = Buffer.from(left);
  const b = Buffer.from(right);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

function base64url(value) {
  return Buffer.from(value).toString('base64url');
}

function createAccountApi({
  store = new JsonAccountStore(),
  jwtSecret = process.env.AUTH_JWT_SECRET || '',
  now = Date.now,
  passwordHash = async (password, salt) => (await scrypt(password, salt, 64)).toString('hex'),
  tokenTtlSeconds = TOKEN_TTL_SECONDS,
  authMinuteLimit = Number(process.env.AUTH_MINUTE_LIMIT || 10),
} = {}) {
  const rateBuckets = new Map();
  const enabled = Buffer.byteLength(jwtSecret) >= 32;

  function makeToken(user) {
    const issuedAt = Math.floor(now() / 1000);
    const jti = crypto.randomUUID();
    const expiresAt = issuedAt + tokenTtlSeconds;
    const header = base64url(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
    const payload = base64url(JSON.stringify({
      sub: user.id,
      email: user.email,
      iat: issuedAt,
      exp: expiresAt,
      jti,
    }));
    const content = `${header}.${payload}`;
    const signature = crypto.createHmac('sha256', jwtSecret).update(content).digest('base64url');
    return { token: `${content}.${signature}`, jti, expiresAt };
  }

  function verifyToken(headerValue) {
    if (!headerValue.startsWith('Bearer ')) return null;
    const token = headerValue.slice(7).trim();
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    const content = `${parts[0]}.${parts[1]}`;
    const signature = crypto.createHmac('sha256', jwtSecret).update(content).digest('base64url');
    if (!safeStringEqual(signature, parts[2])) return null;
    try {
      const header = JSON.parse(Buffer.from(parts[0], 'base64url').toString('utf8'));
      const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8'));
      if (header.alg !== 'HS256' || typeof payload.sub !== 'string' ||
          !Number.isInteger(payload.exp) || payload.exp <= Math.floor(now() / 1000) ||
          typeof payload.jti !== 'string') return null;
      return payload;
    } catch {
      return null;
    }
  }

  function rateLimited(ip) {
    const time = now();
    for (const [key, bucket] of rateBuckets) {
      if (time - bucket.start >= 60000) rateBuckets.delete(key);
    }
    if (rateBuckets.size >= 2000 && !rateBuckets.has(ip)) return true;
    const bucket = rateBuckets.get(ip) || { start: time, count: 0 };
    if (bucket.count >= authMinuteLimit) return true;
    bucket.count++;
    rateBuckets.set(ip, bucket);
    return false;
  }

  function validateAttempt(input) {
    const allowed = new Set([
      'id', 'timestamp', 'isExam', 'topic', 'totalQuestions', 'correct', 'wrong',
      'skipped', 'durationSeconds', 'expired', 'answers', 'questionIds',
    ]);
    if (!input || typeof input !== 'object' || Array.isArray(input) ||
        Object.keys(input).some((key) => !allowed.has(key))) return null;
    if (typeof input.id !== 'string' || input.id.length < 1 || input.id.length > 100 ||
        typeof input.timestamp !== 'string' || !Number.isFinite(Date.parse(input.timestamp)) ||
        typeof input.isExam !== 'boolean' || typeof input.expired !== 'boolean' ||
        !Number.isInteger(input.topic) || input.topic < 0 || input.topic > 20 ||
        !Number.isInteger(input.totalQuestions) || input.totalQuestions < 1 || input.totalQuestions > 100 ||
        !Number.isInteger(input.durationSeconds) || input.durationSeconds < 0 || input.durationSeconds > 86400 ||
        !Number.isInteger(input.correct) || !Number.isInteger(input.wrong) || !Number.isInteger(input.skipped) ||
        !Array.isArray(input.questionIds) || input.questionIds.length !== input.totalQuestions ||
        input.questionIds.some((id) => !Number.isInteger(id) || !questionBank.has(id)) ||
        new Set(input.questionIds).size !== input.questionIds.length ||
        !input.answers || typeof input.answers !== 'object' || Array.isArray(input.answers)) return null;

    const questionIds = new Set(input.questionIds.map(String));
    let correct = 0;
    let wrong = 0;
    for (const [questionId, answer] of Object.entries(input.answers)) {
      const id = Number(questionId);
      const question = questionBank.get(id);
      if (!Number.isInteger(id) || !questionIds.has(questionId) || typeof answer !== 'string' ||
          !question?.options.some((option) => option.id === answer)) return null;
      if (question.correct_answer === answer) correct++;
      else wrong++;
    }
    const skipped = input.totalQuestions - Object.keys(input.answers).length;
    if (correct !== input.correct || wrong !== input.wrong || skipped !== input.skipped) return null;
    return input;
  }

  async function handle({ method, pathname, authHeader = '', rawBody = '', ip = 'unknown' }) {
    if (!enabled) return { status: 503, body: { error: 'auth_not_configured' } };

    const authRoute = pathname === '/api/auth/register' || pathname === '/api/auth/login';
    if (authRoute && rateLimited(ip)) return { status: 429, body: { error: 'rate_limited' } };

    let input;
    if (rawBody) {
      try { input = JSON.parse(rawBody); } catch { return { status: 400, body: { error: 'bad_json' } }; }
    }

    if (method === 'POST' && pathname === '/api/auth/register') {
      if (!input || typeof input !== 'object' || Array.isArray(input) ||
          Object.keys(input).some((key) => !['email', 'password', 'displayName'].includes(key))) {
        return { status: 400, body: { error: 'invalid_registration' } };
      }
      const email = normalizeEmail(input.email);
      const displayName = typeof input.displayName === 'string' ? input.displayName.trim() : '';
      if (!email || typeof input.password !== 'string' || input.password.length < 8 ||
          Buffer.byteLength(input.password) > 128 || displayName.length > 80) {
        return { status: 400, body: { error: 'invalid_registration' } };
      }
      const salt = crypto.randomBytes(16).toString('hex');
      const user = {
        id: crypto.randomUUID(), email,
        displayName: displayName || email.split('@')[0],
        passwordSalt: salt,
        passwordHash: await passwordHash(input.password, salt),
        createdAt: new Date(now()).toISOString(),
      };
      const issued = makeToken(user);
      const created = await store.mutate((data) => {
        if (data.users.some((item) => item.email === email)) return false;
        data.users.push(user);
        data.sessions.push({ jti: issued.jti, userId: user.id, expiresAt: issued.expiresAt });
        data.authEvents.push({ id: crypto.randomUUID(), userId: user.id, type: 'register', at: user.createdAt });
        data.authEvents = data.authEvents.slice(-MAX_AUTH_EVENTS);
        return true;
      });
      if (!created) return { status: 409, body: { error: 'email_already_registered' } };
      return { status: 201, body: { token: issued.token, user: publicUser(user) } };
    }

    if (method === 'POST' && pathname === '/api/auth/login') {
      if (!input || typeof input !== 'object' || Array.isArray(input) ||
          Object.keys(input).some((key) => !['email', 'password'].includes(key))) {
        return { status: 400, body: { error: 'invalid_credentials' } };
      }
      const email = normalizeEmail(input.email);
      if (!email || typeof input.password !== 'string' || Buffer.byteLength(input.password) > 128) {
        return { status: 401, body: { error: 'invalid_credentials' } };
      }
      const user = await store.read((data) => data.users.find((item) => item.email === email));
      const salt = user?.passwordSalt || '0'.repeat(32);
      const actualHash = await passwordHash(input.password, salt);
      if (!user || !safeStringEqual(actualHash, user.passwordHash)) {
        return { status: 401, body: { error: 'invalid_credentials' } };
      }
      const issued = makeToken(user);
      await store.mutate((data) => {
        const currentTime = Math.floor(now() / 1000);
        data.sessions = data.sessions.filter((session) => session.expiresAt > currentTime);
        data.sessions.push({ jti: issued.jti, userId: user.id, expiresAt: issued.expiresAt });
        data.authEvents.push({ id: crypto.randomUUID(), userId: user.id, type: 'login', at: new Date(now()).toISOString() });
        data.authEvents = data.authEvents.slice(-MAX_AUTH_EVENTS);
      });
      return { status: 200, body: { token: issued.token, user: publicUser(user) } };
    }

    const payload = verifyToken(authHeader);
    if (!payload) return { status: 401, body: { error: 'unauthorized' } };
    const authState = await store.read((data) => ({
      user: data.users.find((item) => item.id === payload.sub),
      active: data.sessions.some((session) => session.jti === payload.jti && session.userId === payload.sub),
    }));
    const user = authState.user;
    if (!user || !authState.active) return { status: 401, body: { error: 'unauthorized' } };

    if (method === 'POST' && pathname === '/api/auth/logout') {
      await store.mutate((data) => {
        data.sessions = data.sessions.filter((session) => session.jti !== payload.jti);
        data.authEvents.push({ id: crypto.randomUUID(), userId: user.id, type: 'logout', at: new Date(now()).toISOString() });
        data.authEvents = data.authEvents.slice(-MAX_AUTH_EVENTS);
      });
      return { status: 204, body: null };
    }
    if (method === 'GET' && pathname === '/api/auth/me') {
      return { status: 200, body: { user: publicUser(user) } };
    }
    if (method === 'GET' && pathname === '/api/auth/events') {
      const events = await store.read((data) => data.authEvents
        .filter((event) => event.userId === user.id)
        .slice(-100)
        .reverse());
      return { status: 200, body: { events } };
    }
    if (method === 'PATCH' && pathname === '/api/auth/me') {
      if (!input || typeof input !== 'object' || Array.isArray(input) ||
          Object.keys(input).some((key) => !['displayName', 'avatarBase64'].includes(key))) {
        return { status: 400, body: { error: 'invalid_profile' } };
      }
      const displayName = typeof input.displayName === 'string' ? input.displayName.trim() : '';
      const avatar = input.avatarBase64;
      if (!displayName || displayName.length > 80 ||
          (avatar !== undefined && avatar !== null &&
            (typeof avatar !== 'string' || avatar.length > 340000 ||
              !/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/.test(avatar)))) {
        return { status: 400, body: { error: 'invalid_profile' } };
      }
      const updated = await store.mutate((data) => {
        const storedUser = data.users.find((item) => item.id === user.id);
        storedUser.displayName = displayName;
        if (avatar !== undefined) storedUser.avatarBase64 = avatar || null;
        data.authEvents.push({ id: crypto.randomUUID(), userId: user.id, type: 'profile_update', at: new Date(now()).toISOString() });
        data.authEvents = data.authEvents.slice(-MAX_AUTH_EVENTS);
        return storedUser;
      });
      return { status: 200, body: { user: publicUser(updated) } };
    }
    if (method === 'GET' && pathname === '/api/history') {
      const attempts = await store.read((data) => data.attempts[user.id] || []);
      return { status: 200, body: { attempts } };
    }
    if (method === 'POST' && pathname === '/api/history') {
      const attempt = validateAttempt(input);
      if (!attempt) return { status: 400, body: { error: 'invalid_attempt' } };
      await store.mutate((data) => {
        const attempts = data.attempts[user.id] || [];
        data.attempts[user.id] = [attempt, ...attempts.filter((item) => item.id !== attempt.id)]
          .sort((a, b) => Date.parse(b.timestamp) - Date.parse(a.timestamp))
          .slice(0, MAX_HISTORY);
        data.authEvents.push({ id: crypto.randomUUID(), userId: user.id, type: 'quiz_attempt', at: new Date(now()).toISOString() });
        data.authEvents = data.authEvents.slice(-MAX_AUTH_EVENTS);
      });
      return { status: 201, body: { attempt } };
    }
    if (method === 'DELETE' && pathname === '/api/history') {
      await store.mutate((data) => { delete data.attempts[user.id]; });
      return { status: 204, body: null };
    }
    const deleteMatch = pathname.match(/^\/api\/history\/([A-Za-z0-9_-]{1,100})$/);
    if (method === 'DELETE' && deleteMatch) {
      await store.mutate((data) => {
        data.attempts[user.id] = (data.attempts[user.id] || []).filter((item) => item.id !== deleteMatch[1]);
      });
      return { status: 204, body: null };
    }
    return { status: 404, body: { error: 'not_found' } };
  }

  return { handle, enabled };
}

function publicUser(user) {
  return {
    id: user.id,
    email: user.email,
    displayName: user.displayName,
    createdAt: user.createdAt,
    ...(user.avatarBase64 ? { avatarBase64: user.avatarBase64 } : {}),
  };
}

module.exports = { createAccountApi, JsonAccountStore, MAX_HISTORY };
