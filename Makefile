export GO111MODULE=on

# TODO: 実際の値に合わせてTODO部分を変更する
####################################################################
DB_HOST:=127.0.0.1
DB_PORT:=3306
DB_USER:=isucon
DB_PASS:=isucon
DB_NAME:=isuride

SERVICE:=isuride-go.service
ALPM:="/api/app/rides/.+/evaluation,/api/chair/rides/.+/status,/assets/.+,/images/.+"
####################################################################

MYSQL_CMD:=mysql -h$(DB_HOST) -P$(DB_PORT) -u$(DB_USER) -p$(DB_PASS) $(DB_NAME)

NGX_LOG_FOR_ALP:=/tmp/access_for_alp.log
MYSQL_LOG:=/tmp/slow-query.log

.PHONY: restart
restart:
	sudo systemctl restart $(SERVICE)

.PHONY: before-profile
before-profile: restart-infra slow-on

.PHONY: restart-infra
restart-infra:
	$(eval when := $(shell date "+%s"))
	mkdir -p ~/logs/$(when)
	@if [ -f $(NGX_LOG_FOR_ALP) ]; then \
		sudo mv -f $(NGX_LOG_FOR_ALP) ~/logs/$(when)/ ; \
	fi
	@if [ -f $(MYSQL_LOG) ]; then \
		sudo mv -f $(MYSQL_LOG) ~/logs/$(when)/ ; \
	fi
	sudo systemctl restart nginx
	sudo systemctl restart mysql

.PHONY: slow
slow: 
	sudo pt-query-digest $(MYSQL_LOG)

.PHONY: alp
alp:
	sudo cat $(NGX_LOG_FOR_ALP) | alp ltsv -r --sort=sum -m $(ALPM)

.PHONY: slow-on
slow-on:
	sudo $(MYSQL_CMD) -e "set global slow_query_log_file = '$(MYSQL_LOG)'; set global long_query_time = 0; set global slow_query_log = ON;"

.PHONY: slow-off
slow-off:
	sudo $(MYSQL_CMD) -e "set global slow_query_log = OFF;"
	
.PHONY: connect-db
connect-db:
	sudo $(MYSQL_CMD)