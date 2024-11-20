# Stage 1: Build the Vue project
FROM node:alpine AS build-stage

# Set the working directory inside the container
WORKDIR /app

RUN echo HelloW

# Copy package.json and package-lock.json to the container
COPY package.json package-lock.json ./

# Install dependencies
RUN npm install

# Copy the rest of the project files
COPY . .

# Build the Vue project in standalone mode
#RUN npm run build -- --standalone
RUN npm run build:standalone

# Stage 2: Serve the Vue project with nginx
FROM nginx:alpine AS production-stage

# Copy the built files from the build stage to nginx's default html directory
COPY --from=build-stage /app/dist /usr/share/nginx/html

# Custom nginx configuration for Microfrontend setup
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80 for nginx
#EXPOSE 80
EXPOSE 8096

# Start nginx
CMD ["nginx", "-g", "daemon off;"]

