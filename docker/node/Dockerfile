FROM node:current-alpine

WORKDIR /var/www/client

COPY ./client/package.json /var/www/client/package.json
COPY ./client/package-lock.json /var/www/client/package-lock.json

RUN npm install

COPY /client /var/www/client

USER node

EXPOSE 8080

CMD ["npm", "run", "serve"]
