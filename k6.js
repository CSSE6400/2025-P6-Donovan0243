import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { target: 1000, duration: '1m' },   // 1 分钟内增加到 1000 个用户
    { target: 5000, duration: '10m' }   // 持续 10 分钟高压测试
  ]
};

export default function () {
  const res = http.get('http://taskoverflow-184046664.us-east-1.elb.amazonaws.com/api/v1/todos');
  check(res, {
    'status was 200': (r) => r.status === 200
  });
  sleep(1);
}