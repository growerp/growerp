package org.moqui.impl.service.camel

import groovy.transform.CompileStatic
import org.apache.camel.CamelContext
import org.apache.camel.impl.DefaultCamelContext
import org.apache.camel.CamelExecutionException
import org.apache.camel.Endpoint
import org.apache.camel.ProducerTemplate
import org.apache.camel.Exchange
import org.apache.camel.Processor
import org.apache.camel.Message

import org.moqui.impl.service.ServiceDefinition
import org.moqui.impl.service.ServiceFacadeImpl
import org.moqui.impl.service.ServiceRunner
import org.moqui.impl.service.camel.CamelToolFactory
import org.moqui.service.ServiceException
import org.moqui.impl.service.camel.MoquiServiceConsumer
import org.moqui.context.ExecutionContext
import org.slf4j.Logger
import org.slf4j.LoggerFactory

class CamelRestServices {
    // copied from https://stackoverflow.com/questions/30326760/call-rest-url-using-camel#saves-btn-30328450
    static Map get (ExecutionContext ec) {
        def url = ec.context.url

        CamelContext context = new DefaultCamelContext();

        def responseMap = [:]

        try {
            ProducerTemplate template = context.createProducerTemplate();
            context.start();

            Exchange exchange = template
                    .request( url.replace('://','4://'),
                            new Processor() {
                                public void process(Exchange exchange)
                                        throws Exception {
                                }
                            });

            if (null != exchange) {
                Message out = exchange.getMessage();
                responseMap.response = out.getBody(String.class);
                ec.logger.info("response: ${responseMap.response}");
                int responseCode = out.getHeader(Exchange.HTTP_RESPONSE_CODE,
                        Integer.class);
                ec.logger.info("Response: " + String.valueOf(responseCode));
            }

            Thread.sleep(1000 * 3);
            context.stop();
        } catch (Exception ex) {
            ec.logger.info("Exception: " + ex);
        }
        return ['result':responseMap]
        ec.logger.info("DONE!!");

    }
}