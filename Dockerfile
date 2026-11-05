FROM node:20-alpine
WORKDIR /app
RUN npm install -g omniroute
EXPOSE 20128
CMD ["omniroute", "serve"]
