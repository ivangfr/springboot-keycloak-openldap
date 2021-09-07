package com.mycompany.simpleservice;

import org.apache.logging.log4j.message.ParameterizedMessageFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.nativex.hint.NativeHint;
import org.springframework.nativex.hint.TypeHint;

@NativeHint(
        options = "--enable-https",
        types = @TypeHint(types = ParameterizedMessageFactory.class)
)
@SpringBootApplication
public class SimpleServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(SimpleServiceApplication.class, args);
    }

}
