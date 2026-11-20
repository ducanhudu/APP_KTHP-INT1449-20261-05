const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createServer } = require('./server');

async function setup(t, options = {}) {
  const calls = [];
  const server = createServer({
    apiKey: 'fake-provider-key', accessCode: 'test-access',
    fetchImpl: async (url, init) => {
      calls.push(JSON.parse(init.body));
      return new Response(JSON.stringify({ candidates: [{ content: { parts: [{ text: 'Explanation' }] } }] }));
    }, ...options,
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise(resolve => { server.closeAllConnections(); server.close(resolve); }));
  const post = (body, token = 'test-access') => fetch(`http://127.0.0.1:${server.address().port}/explain`, {
    method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
    body: JSON.stringify(body),
  });
  return { post, calls };
}
test('Reject missing or wrong access code before calling provider', async t => {
  const { post, calls } = await setup(t);
  assert.equal((await post({ questionId: 1, language: 'vi' }, '')).status, 401);
  assert.equal((await post({ questionId: 1, language: 'vi' }, 'wrong')).status, 401);
  assert.equal(calls.length, 0);
});
test('Reject arbitrary prompts, unknown IDs and unsupported languages', async t => {
  const { post, calls } = await setup(t);
  for (const body of [null, { contents: [] }, { questionId: 999, language: 'vi' },
    { questionId: 1, language: 'fr' }, { questionId: 1, language: 'vi', prompt: 'Write a poem' }]) {
    assert.equal((await post(body)).status, 400);
  }
  assert.equal(calls.length, 0);
});
test('Build authoritative prompt with choices and cache by question + language', async t => {
  const { post, calls } = await setup(t);
  assert.equal((await post({ questionId: 1, language: 'en' })).status, 200);
  assert.equal((await post({ questionId: 1, language: 'en' })).status, 200);
  assert.equal(calls.length, 1);
  assert.match(calls[0].contents[0].parts[0].text, /C\. const/);
  assert.equal(calls[0].generationConfig.maxOutputTokens, 600);
  await post({ questionId: 1, language: 'vi' });
  assert.equal(calls.length, 2);
});
test('Enforce minute limit even for cached questions', async t => {
  const { post, calls } = await setup(t, { minuteLimit: 1 });
  await post({ questionId: 1, language: 'vi' });
  assert.equal((await post({ questionId: 1, language: 'vi' })).status, 429);
  assert.equal(calls.length, 1);
});
test('Enforce daily provider budget and reset next day', async t => {
  let time = Date.now();
  const { post, calls } = await setup(t, { dailyLimit: 1, now: () => time });
  await post({ questionId: 1, language: 'vi' });
  assert.equal((await post({ questionId: 2, language: 'vi' })).status, 429);
  time += 86400000;
  assert.equal((await post({ questionId: 2, language: 'vi' })).status, 200);
  assert.equal(calls.length, 2);
});
test('Sanitize provider errors and fail closed when not configured', async t => {
  const broken = await setup(t, { fetchImpl: async () => { throw new Error('secret'); } });
  const response = await broken.post({ questionId: 1, language: 'vi' });
  assert.equal(response.status, 502);
  assert.equal(JSON.stringify(await response.json()).includes('secret'), false);
  const missing = await setup(t, { accessCode: '' });
  assert.equal((await missing.post({ questionId: 1, language: 'vi' })).status, 503);
});
