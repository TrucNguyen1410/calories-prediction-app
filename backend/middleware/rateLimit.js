// Rate limiter đơn giản dùng bộ nhớ trong (in-memory sliding window) theo IP.
// Không phụ thuộc thư viện ngoài để đảm bảo build/deploy nhẹ và ổn định.
// Dùng để chặn lạm dụng các API tốn kém (gọi LLM Groq) và bảo vệ quota.

/**
 * @param {object} opts
 * @param {number} opts.windowMs cửa sổ thời gian (ms)
 * @param {number} opts.max số request tối đa trong cửa sổ
 * @param {string} opts.message thông báo khi vượt giới hạn
 */
export function rateLimit({ windowMs = 60_000, max = 30, message } = {}) {
    const hits = new Map(); // key -> number[] (mốc thời gian request)

    // Dọn rác định kỳ để tránh rò rỉ bộ nhớ
    const cleanup = setInterval(() => {
        const now = Date.now();
        for (const [key, times] of hits.entries()) {
            const fresh = times.filter((t) => now - t < windowMs);
            if (fresh.length === 0) hits.delete(key);
            else hits.set(key, fresh);
        }
    }, windowMs);
    // Không giữ tiến trình sống chỉ vì timer này
    if (cleanup.unref) cleanup.unref();

    return (req, res, next) => {
        const now = Date.now();
        // Ưu tiên userId (nếu đã xác thực), nếu chưa thì theo IP
        const key = req.userId || req.ip || req.headers["x-forwarded-for"] || "anon";

        const times = (hits.get(key) || []).filter((t) => now - t < windowMs);
        times.push(now);
        hits.set(key, times);

        if (times.length > max) {
            const retryAfter = Math.ceil(windowMs / 1000);
            res.set("Retry-After", String(retryAfter));
            return res.status(429).json({
                success: false,
                message:
                    message ||
                    `Bạn thao tác quá nhanh. Vui lòng thử lại sau ${retryAfter} giây.`,
            });
        }
        next();
    };
}

export default rateLimit;
