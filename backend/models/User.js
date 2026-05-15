import mongoose from 'mongoose';
import bcrypt from 'bcryptjs'; 

const UserSchema = new mongoose.Schema({
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true, index: true },
    password: { type: String, required: true },
    dob: { type: Date },
    
    // --- CÁC TRƯỜNG MỚI ĐƯỢC THÊM VÀO ---
    gender: { type: String, enum: ['Nam', 'Nữ', 'Khác'] },
    height: { type: Number, default: 0 }, 
    weight: { type: Number, default: 0 },
    
    // --- GOOGLE OAUTH FIELDS ---
    googleId: { type: String, unique: true, sparse: true },
    googleAccessToken: { type: String },
    googleRefreshToken: { type: String }
    // -------------------------

}, { timestamps: true });

// Mã hóa mật khẩu (Giữ nguyên)
UserSchema.pre('save', async function(next) {
    if (!this.isModified('password')) {
        return next();
    }
    try {
        const salt = await bcrypt.genSalt(10);
        this.password = await bcrypt.hash(this.password, salt);
        next();
    } catch (err) {
        next(err);
    }
});

export default mongoose.model('User', UserSchema);