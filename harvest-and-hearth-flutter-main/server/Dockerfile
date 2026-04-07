# Docker — build context = thư mục server/ (đặt Root directory = server khi deploy từ Git)
FROM node:20-alpine

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY src ./src

ENV NODE_ENV=production

# Nền tảng cloud thường gán PORT; EXPOSE chỉ mang tính tài liệu
EXPOSE 8000

CMD ["node", "src/index.js"]
