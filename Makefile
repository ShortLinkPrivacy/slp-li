COFFEE=$(shell which coffee)
NODE=$(shell which node)
APP=server.js
MOCHA=$(shell which mocha)
NPM=$(shell which npm)

help:
	@echo "Available targets:"
	@echo "install     - install all modules"
	@echo "build       - compile all files"
	@echo "clean       - remove all installed modules"
	@echo "start       - run application in development mode"
	@echo "deploy      - run application in production mode"
	@echo "restart     - restart application in production mode"
	@echo "test        - run all test"

install:
	$(NPM) install

build:
	$(COFFEE) -c ./ t/

clean:
	rm -rf node_modules/

start:
	$(COFFEE) -c ./
	$(NODE) $(APP)

deploy:
	$(COFFEE) -c ./
	NODE_ENV=production forever -o log/forever_output.log -e log/forever_error.log $(APP) &

restart:
	$(COFFEE) -c ./
	forever restart $(APP)

test:
	$(COFFEE) -c t
	NODE_ENV=test mocha t

mintest:
	$(COFFEE) -c t
	NODE_ENV=test mocha -R min t
