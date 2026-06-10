const request = require('supertest');
const app = require('./index');

test('GET /ping répond pong', async () => {
  const res = await request(app).get('/ping');
  expect(res.statusCode).toBe(200);
  expect(res.body.message).toBe('pong');
});
