# Use the official Node.js image
FROM node:18-slim

# Create and change to the app directory
WORKDIR /app

# Copy application dependency manifests to the container image
COPY package*.json ./

# Install production dependencies
RUN npm install --production

# Copy local code to the container image
COPY . .

# Run the web service on container startup
CMD [ "node", "index.js" ]