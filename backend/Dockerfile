# Sử dụng Image chứa sẵn cả Python và Node.js
FROM nikolaik/python-nodejs:python3.9-nodejs18

# Tạo thư mục làm việc
WORKDIR /app

# Copy và cài đặt thư viện Node.js
COPY package*.json ./
RUN npm install

# Copy và cài đặt thư viện Python
COPY requirements.txt ./
RUN pip install -r requirements.txt

# Copy toàn bộ code vào
COPY . .

# Mở cổng (Render thường dùng biến môi trường PORT, nhưng cứ expose 3000 để chắc chắn)
EXPOSE 3000

# Lệnh chạy server
CMD ["node", "server.js"]