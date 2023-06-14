
#FROM node:14-alpine as build
FROM node:14.20.1-alpine as build
WORKDIR /app
#RUN npm install -g @angular/cli
COPY package.json package-lock.json ./
#RUN npm cache clean --force
#RUN npm i -g @angular/cli
#RUN npm install
RUN npm ci --no-audit
#RUN npm i -g @angular/cli@14.1.3
#RUN ngcc
COPY . .
#RUN node --max_old_space_size=8192 ./node_modules/@angular/cli/bin/ng build --prod
#RUN ng build --prod
#CMD RUN npm run build:prod
RUN npm run build
#stage 2
#FROM nginx:alpine
FROM nginx:latest AS ngi
COPY --from=build /app/dist/payrollCO /usr/share/nginx/html
COPY /nginx.conf  /etc/nginx/conf.d/default.conf
EXPOSE 80   