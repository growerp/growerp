/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.acme.rest.json;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;

import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.model.rest.RestBindingMode;

/**
 * Camel route definitions.
 */
public class Routes extends RouteBuilder {
    private final Set<Fruit> fruits = Collections.synchronizedSet(new LinkedHashSet<>());
    private final Set<Legume> legumes = Collections.synchronizedSet(new LinkedHashSet<>());

    private final Map<String, Object> fruitMap = Collections.synchronizedMap(new LinkedHashMap<>());

    public Routes() {

        /* Let's add some initial fruits */
        this.fruits.add(new Fruit("Apple", "Winter fruit"));
        this.fruits.add(new Fruit("Pineapple", "Tropical fruit"));
        this.fruitMap.put("result", this.fruits);
        this.fruitMap.put("message", "OK");

        /* Let's add some initial legumes */
        this.legumes.add(new Legume("Carrot", "Root vegetable, usually orange"));
        this.legumes.add(new Legume("Zucchini", "Summer squash"));
    }

    @Override
    public void configure() throws Exception {

        restConfiguration().bindingMode(RestBindingMode.json);

        rest("/rest/fruits")
                .get()
                .to("direct:getFruitMap")

                .post()
                .type(Fruit.class)
                .to("direct:addFruit");

        rest("/legumes")
                .get()
                .to("direct:getLegumes");

        from("direct:getFruitMap")
                .setBody().constant(fruitMap);

        from("direct:addFruit")
                .process().body(Fruit.class, fruits::add)
                .setBody().constant(fruitMap);

        from("direct:getLegumes")
                .setBody().constant(legumes);
    }
}
