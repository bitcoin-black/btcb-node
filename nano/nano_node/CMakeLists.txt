add_executable (btcb_node
	daemon.cpp
	daemon.hpp
	entry.cpp)

target_link_libraries (btcb_node
	node
	rpc
	secure
	argon2
	Boost::boost
	${PLATFORM_LIBS}
)

if (NANO_STACKTRACE_BACKTRACE)
	target_link_libraries(btcb_node backtrace)
endif ()

target_compile_definitions(btcb_node
	PRIVATE
		-DTAG_VERSION_STRING=${TAG_VERSION_STRING}
		-DGIT_COMMIT_HASH=${GIT_COMMIT_HASH}
		-DBOOST_PROCESS_SUPPORTED=${BOOST_PROCESS_SUPPORTED})

set_target_properties (btcb_node
	PROPERTIES
		COMPILE_FLAGS
			"-DQT_NO_KEYWORDS -DBOOST_ASIO_HAS_STD_ARRAY=1")

add_custom_command(TARGET btcb_node
				   POST_BUILD
				   COMMAND btcb_node --generate_config node > ${PROJECT_BINARY_DIR}/config-node.toml.sample
				   COMMAND btcb_node --generate_config rpc > ${PROJECT_BINARY_DIR}/config-rpc.toml.sample)

if ((NANO_GUI OR RAIBLOCKS_GUI) AND NOT APPLE)
	install(TARGETS btcb_node
			RUNTIME DESTINATION .
	)
endif()
