const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');
const questions = require('../assets/flutter_quiz_300.json');
const { createServer } = require('./server');
const { JsonAccountStore } = require('./accounts');

const bank = new Map(questions.map((question) => [question.id, question]));

async function setup(t, extra = {}) {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'flutter-lab-accounts-'));
  const server = createServer({
    apiKey: 'fake-ai-key',
    accessCode: 'test-ai-code',
    jwtSecret: 'test-only-jwt-secret-which-is-at-least-32-bytes',
    store: new JsonAccountStore(path.join(dir, 'store.json')),
    ...extra,
  });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  t.after(async () => {
    await new Promise((resolve) => { server.closeAllConnections(); server.close(resolve); });
    await fs.rm(dir, { recursive: true, force: true });
  });
  const base = `http://127.0.0.1:${server.address().port}`;
  const call = async (route, { method = 'GET', token, body, headers: extraHeaders } = {}) => fetch(`${base}${route}`, {
    method,
    headers: {
      ...(body === undefined ? {} : { 'Content-Type': 'application/json' }),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...extraHeaders,
    },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });
  return { call, dir };
}

async function register(call, email) {
  const response = await call('/api/auth/register', {
    method: 'POST', body: { email, password: 'correct-horse-42', displayName: 'Quiz Learner' },
  });
  return { response, data: await response.json() };
}

function attempt(id, ids = [1, 2]) {
  const answers = {};
  for (const questionId of ids) answers[questionId] = bank.get(questionId).correct_answer;
  return {
    id,
    timestamp: new Date().toISOString(),
    isExam: false,
    topic: 0,
    totalQuestions: ids.length,
    correct: ids.length,
    wrong: 0,
    skipped: 0,
    durationSeconds: 40,
    expired: false,
    answers,
    questionIds: ids,
  };
}

test('register, normalize email, hash password and record auth events', async (t) => {
  const { call, dir } = await setup(t);
  const { response, data } = await register(call, ' Student@Example.com ');
  assert.equal(response.status, 201);
  assert.equal(data.user.email, 'student@example.com');
  assert.equal(data.user.displayName, 'Quiz Learner');
  assert.ok(data.token);
  assert.equal('passwordHash' in data.user, false);
  const raw = await fs.readFile(path.join(dir, 'store.json'), 'utf8');
  const stored = JSON.parse(raw);
  assert.notEqual(stored.users[0].passwordHash, 'correct-horse-42');
  assert.equal(stored.authEvents[0].type, 'register');
});

test('duplicate registration and malformed or weak credentials are rejected', async (t) => {
  const { call } = await setup(t);
  assert.equal((await call('/api/auth/register', { method: 'POST', body: { email: 'bad', password: 'short' } })).status, 400);
  assert.equal((await call('/api/auth/register', {
    method: 'POST', headers: { 'Content-Type': 'text/plain' }, body: '{"email":"x@example.com"}',
  })).status, 415);
  assert.equal((await register(call, 'same@example.com')).response.status, 201);
  assert.equal((await register(call, 'SAME@example.com')).response.status, 409);
  assert.equal((await call('/api/auth/login', { method: 'POST', body: { email: 'same@example.com', password: 'incorrect' } })).status, 401);
});

test('login returns a usable token and persists a login event', async (t) => {
  const { call, dir } = await setup(t);
  await register(call, 'learner@example.com');
  const response = await call('/api/auth/login', {
    method: 'POST', body: { email: 'LEARNER@example.com', password: 'correct-horse-42' },
  });
  const data = await response.json();
  assert.equal(response.status, 200);
  assert.equal((await call('/api/auth/me', { token: data.token })).status, 200);
  const eventResponse = await call('/api/auth/events', { token: data.token });
  assert.deepEqual((await eventResponse.json()).events.map((event) => event.type), ['login', 'register']);
  const stored = JSON.parse(await fs.readFile(path.join(dir, 'store.json'), 'utf8'));
  assert.deepEqual(stored.authEvents.map((event) => event.type), ['register', 'login']);
});

test('profile updates are validated and persisted for the signed-in account', async (t) => {
  const { call } = await setup(t);
  const { data } = await register(call, 'profile@example.com');
  const response = await call('/api/auth/me', {
    method: 'PATCH', token: data.token,
    body: { displayName: 'Updated Name', avatarBase64: Buffer.from('avatar').toString('base64') },
  });
  const updated = await response.json();
  assert.equal(response.status, 200);
  assert.equal(updated.user.displayName, 'Updated Name');
  assert.equal(updated.user.avatarBase64, Buffer.from('avatar').toString('base64'));
  assert.equal((await call('/api/auth/me', {
    method: 'PATCH', token: data.token,
    body: { displayName: '', avatarBase64: 'bad!' },
  })).status, 400);
});

test('history is private per account, validates answers and survives server restart', async (t) => {
  const first = await setup(t);
  const secondUser = await register(first.call, 'alice@example.com');
  const otherUser = await register(first.call, 'bob@example.com');
  const tokenA = secondUser.data.token;
  const tokenB = otherUser.data.token;
  const score = attempt('attempt-1');
  assert.equal((await first.call('/api/history', { method: 'POST', token: tokenA, body: score })).status, 201);
  assert.equal((await first.call('/api/history', { method: 'POST', token: tokenB, body: score })).status, 201);
  const invalid = { ...attempt('forged'), correct: 0 };
  assert.equal((await first.call('/api/history', { method: 'POST', token: tokenA, body: invalid })).status, 400);
  const listA = await (await first.call('/api/history', { token: tokenA })).json();
  const listB = await (await first.call('/api/history', { token: tokenB })).json();
  assert.equal(listA.attempts.length, 1);
  assert.equal(listB.attempts.length, 1);
  assert.equal((await first.call('/api/history/attempt-1', { method: 'DELETE', token: tokenA })).status, 204);
  assert.equal((await (await first.call('/api/history', { token: tokenB })).json()).attempts.length, 1);

  // A new server/store instance sees persisted users and attempts.
  const dir = first.dir;
  const restarted = await setup(t, { store: new JsonAccountStore(path.join(dir, 'store.json')) });
  assert.equal((await (await restarted.call('/api/history', { token: tokenB })).json()).attempts.length, 1);
});

test('concurrent registrations and history writes do not lose updates', async (t) => {
  const { call } = await setup(t);
  const concurrent = await Promise.all([
    register(call, 'race@example.com'),
    register(call, 'RACE@example.com'),
  ]);
  assert.deepEqual(concurrent.map((item) => item.response.status).sort(), [201, 409]);
  const { data } = concurrent.find((item) => item.response.status === 201);
  const writes = await Promise.all(Array.from({ length: 6 }, (_, index) =>
    call('/api/history', { method: 'POST', token: data.token, body: attempt(`concurrent-${index}`) }),
  ));
  assert.ok(writes.every((response) => response.status === 201));
  const stored = await (await call('/api/history', { token: data.token })).json();
  assert.equal(stored.attempts.length, 6);
});

test('reject missing/invalid tokens and disable accounts without a strong JWT secret', async (t) => {
  const { call } = await setup(t);
  assert.equal((await call('/api/history')).status, 401);
  assert.equal((await call('/api/auth/me', { token: 'forged.token.value' })).status, 401);
  const disabled = await setup(t, { jwtSecret: 'too-short' });
  assert.equal((await disabled.call('/api/auth/register', {
    method: 'POST', body: { email: 'x@example.com', password: 'correct-horse-42' },
  })).status, 503);
});

test('logout revokes the bearer token on the server', async (t) => {
  const { call } = await setup(t);
  const { data } = await register(call, 'logout@example.com');
  assert.equal((await call('/api/auth/logout', { method: 'POST', token: data.token })).status, 204);
  assert.equal((await call('/api/auth/me', { token: data.token })).status, 401);
});

test('apply authentication request rate limit', async (t) => {
  const { call } = await setup(t, { authMinuteLimit: 1 });
  assert.equal((await call('/api/auth/login', {
    method: 'POST', body: { email: 'x@example.com', password: 'bad-password' },
  })).status, 401);
  assert.equal((await call('/api/auth/login', {
    method: 'POST', body: { email: 'x@example.com', password: 'bad-password' },
  })).status, 429);
});
