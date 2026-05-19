import mongoose from 'mongoose';

const MessageItemSchema = new mongoose.Schema({
    id: { type: String }, // client-side ID
    role: { type: String, enum: ['user', 'model'], required: true },
    content: { type: String, required: true },
    isActionable: { type: Boolean, default: false },
    actionType: { type: String },
    actionData: { type: mongoose.Schema.Types.Mixed },
    isSaved: { type: Boolean, default: false },
    timestamp: { type: Date, default: Date.now }
});

const ChatSessionSchema = new mongoose.Schema({
    userId: { 
        type: mongoose.Schema.Types.ObjectId, 
        ref: 'User', 
        required: true,
        index: true 
    },
    sessionTitle: { type: String, default: "Cuộc trò chuyện mới" },
    messages: [MessageItemSchema],
}, { timestamps: true });

export default mongoose.model('ChatSession', ChatSessionSchema);
