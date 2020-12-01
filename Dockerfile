FROM fedora:33
RUN dnf install -y ruby git
WORKDIR /app
ADD ./ /app/
RUN bundle install
ENTRYPOINT bundle exec ruby bin/mqpi
