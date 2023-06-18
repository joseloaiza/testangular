
#FROM node:14.20.1-alpine as build
FROM node:16.20.0-alpine as build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install -g npm@9.6.6
#RUN npm cache clean --force
#RUN node --max_old_space_size=8192 ./node_modules/@angular/cli/bin/ng build --prod
#RUN ng build --prod
#CMD RUN npm run build:prod
RUN npm ci
COPY . .
RUN npm run build --prod
#stage 2
#FROM nginx:alpine
FROM nginx:latest AS ngi
COPY --from=build app/dist/testangular /usr/share/nginx/html
COPY /nginx.conf  /etc/nginx/conf.d/default.conf
EXPOSE 80   