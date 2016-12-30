build:
	docker build -f ./Dockerfile \
                    --label org.label-schema.vcs-url=`git config --get remote.origin.url` \
                    --label org.label-schema.vcs-ref=`git show --oneline -s|cut -d' ' -f 1` \
                    --label org.label-schema.build-date=`date '+%FT%T%z'` \
                    --label org.label-schema.version=0.1 \
                    -t sftp .
