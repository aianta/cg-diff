FROM node:10-alpine

#Create app directory
WORKDIR /usr/app
COPY package*.json ./
RUN npm install
COPY dist /usr/app/dist
COPY server.js /usr/app


EXPOSE 5000

CMD ["node", "server"]
