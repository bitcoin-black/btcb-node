FROM bitcoin-black/btcb-env:gcc

ARG NETWORK=live
ARG TRAVIS_TAG=DEV_BUILD
ARG CI_BUILD=OFF
ADD ./ /tmp/src

RUN mkdir /tmp/build && \
    cd /tmp/build && \
    cmake /tmp/src -DCI_BUILD=${CI_BUILD} -DBOOST_ROOT=${BOOST_ROOT} -DACTIVE_NETWORK=btcb_${NETWORK}_network \
    -DBTCB_ROCKSDB=ON -DBTCB_POW_SERVER=ON -DROCKSDB_LIBRARIES=/tmp/rocksdb/lib/librocksdb.a \
    -DROCKSDB_INCLUDE_DIRS=/tmp/rocksdb/include -DBTCB_SHARED_BOOST=ON && \
    make btcb_node -j $(nproc) && \
    make btcb_rpc -j $(nproc) && \
    make btcb_pow_server -j $(nproc) && \
    cd .. && \
    echo ${NETWORK} > /etc/btcb-network

FROM ubuntu:16.04

RUN groupadd --gid 1000 bitcoin-black && \
    useradd --uid 1000 --gid bitcoin-black --shell /bin/bash --create-home bitcoin-black

COPY --from=0 /tmp/build/btcb_node /usr/bin
COPY --from=0 /tmp/build/btcb_rpc /usr/bin
COPY --from=0 /tmp/build/btcb_pow_server /usr/bin
COPY --from=0 /tmp/src/api/ /usr/bin/api/
COPY --from=0 /etc/btcb-network /etc
COPY docker/node/entry.sh /usr/bin/entry.sh
COPY docker/node/config /usr/share/btcb/config
COPY --from=0 /tmp/boost/lib/* /usr/local/lib/
RUN chmod +x /usr/bin/entry.sh
RUN ln -s /usr/bin/btcb_node /usr/bin/rai_node
RUN ldconfig

WORKDIR /root
USER root

ENV PATH="${PATH}:/usr/bin"
ENTRYPOINT ["/bin/bash",  "/usr/bin/entry.sh"]
CMD ["btcb_node daemon -l"]
