FROM node:20-alpine

# Install build tools for native modules like bcrypt
RUN apk add --no-cache make gcc g++ python3

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY prisma ./prisma/

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Generate Prisma Client
RUN npx prisma generate

# Build the application
RUN npm run build

# Expose port (railway will override if needed)
EXPOSE 8080

# Start command
CMD ["npm", "run", "start:prod"]
