// Kiểm thử middleware validation (không cần server/DB thật — dùng req/res giả).
import { test } from "node:test";
import assert from "node:assert/strict";
import { validateRegister, validatePredictInput } from "../middleware/validate.js";

// Helper tạo res giả để bắt status/json
function mockRes() {
    return {
        statusCode: 200,
        body: null,
        status(code) {
            this.statusCode = code;
            return this;
        },
        json(payload) {
            this.body = payload;
            return this;
        },
    };
}

test("validateRegister từ chối email sai định dạng", () => {
    const req = { body: { name: "Nguyen Van A", email: "sai-email", password: "123456" } };
    const res = mockRes();
    let nextCalled = false;
    validateRegister(req, res, () => (nextCalled = true));
    assert.equal(nextCalled, false);
    assert.equal(res.statusCode, 400);
});

test("validateRegister từ chối mật khẩu quá ngắn", () => {
    const req = { body: { name: "Nguyen Van A", email: "a@b.com", password: "123" } };
    const res = mockRes();
    let nextCalled = false;
    validateRegister(req, res, () => (nextCalled = true));
    assert.equal(nextCalled, false);
    assert.equal(res.statusCode, 400);
});

test("validateRegister cho qua dữ liệu hợp lệ", () => {
    const req = { body: { name: "Nguyen Van A", email: "a@b.com", password: "123456" } };
    const res = mockRes();
    let nextCalled = false;
    validateRegister(req, res, () => (nextCalled = true));
    assert.equal(nextCalled, true);
});

test("validatePredictInput chặn giá trị ngoài khoảng", () => {
    const req = { body: { weight: 5000, height: 175, age: 25, duration: 30, heartRate: 130 } };
    const res = mockRes();
    let nextCalled = false;
    validatePredictInput(req, res, () => (nextCalled = true));
    assert.equal(nextCalled, false);
    assert.equal(res.statusCode, 400);
});

test("validatePredictInput cho qua dữ liệu hợp lệ", () => {
    const req = { body: { weight: 65, height: 170, age: 25, duration: 45, heartRate: 130 } };
    const res = mockRes();
    let nextCalled = false;
    validatePredictInput(req, res, () => (nextCalled = true));
    assert.equal(nextCalled, true);
});
