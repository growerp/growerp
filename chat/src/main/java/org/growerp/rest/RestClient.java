package org.growerp.rest;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.InputStreamReader;
import java.io.UnsupportedEncodingException;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.util.HashMap;
import java.util.Map;

import org.growerp.model.Message;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class RestClient {
	private String urlString;
    Logger logger = LoggerFactory.getLogger(RestClient.class);

    public RestClient(String url) {
        this.urlString = url;
    }
    
    public Boolean validate(String apiKey) {
        Boolean result = false;
        String fullUrl = urlString + "Authenticate";
        try {
            URL url = new URL(fullUrl);
            HttpURLConnection con = (HttpURLConnection) url.openConnection();
            con.setRequestMethod("GET");
            con.setRequestProperty("Content-Type", "application/json");
            con.setRequestProperty("api_key", apiKey);
            con.setConnectTimeout(5000);
            con.setReadTimeout(5000);        
            int status = con.getResponseCode();

            if(status == 200) {
                BufferedReader in = new BufferedReader(
                    new InputStreamReader(con.getInputStream()));
                  String inputLine;
                  StringBuffer content = new StringBuffer();
                  while ((inputLine = in.readLine()) != null) {
                      content.append(inputLine);
                  }
                  if (content.toString().contains("authenticate")) result = true;
                  else logger.error("authenticate not found in: " + content.toString()); 
                  in.close();
            } else {
                logger.error("Validation request error for url: " + fullUrl + " response code: " + status);
            }
            con.disconnect();
        } catch (Exception ex) {
            logger.error("Validation request failed for url: " + fullUrl + " error: " + ex);
        }
        return result;

    }    
    
    public Boolean storeMessage(String apiKey, Message message) {
        Boolean result = false;
        Logger logger = LoggerFactory.getLogger(RestClient.class);
        String fullUrl = urlString + "ChatMessage";
        try {
            URL url = new URL(fullUrl);
            HttpURLConnection con = (HttpURLConnection) url.openConnection();
            con.setRequestMethod("POST");
            con.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
            con.setRequestProperty("api_key", apiKey);
            con.setConnectTimeout(5000);
            con.setReadTimeout(5000);
            // prepare parameters
            Map<String, String> parameters = new HashMap<>();
            parameters.put("message", message.getContent());
            parameters.put("chatRoomId", message.getChatRoomId());
            con.setDoOutput(true);
            DataOutputStream out = new DataOutputStream(con.getOutputStream());
            out.writeBytes(ParameterStringBuilder.getParamsString(parameters));
            out.flush();
            out.close();
            // make request      
            int status = con.getResponseCode();
            if(status == 200) {
                result = true;
            }
            con.disconnect();
        } catch (Exception ex) {
            logger.info("Validation request not worked for url: " + fullUrl + " error: " + ex);
        }
        return result;
    }

    public static class ParameterStringBuilder {
        public static String getParamsString(Map<String, String> params) 
          throws UnsupportedEncodingException{
            StringBuilder result = new StringBuilder();
    
            for (Map.Entry<String, String> entry : params.entrySet()) {
              result.append(URLEncoder.encode(entry.getKey(), "UTF-8"));
              result.append("=");
              result.append(URLEncoder.encode(entry.getValue(), "UTF-8"));
              result.append("&");
            }
    
            String resultString = result.toString();
            return resultString.length() > 0
              ? resultString.substring(0, resultString.length() - 1)
              : resultString;
        }
    }
    
}

