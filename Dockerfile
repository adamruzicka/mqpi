FROM fedora:33
RUN dnf install -y ruby git procps-ng
WORKDIR /app
ADD ./ /app/
RUN bundle install
ENTRYPOINT ["/usr/bin/bundle", "exec", "ruby", "bin/mqpi"]
