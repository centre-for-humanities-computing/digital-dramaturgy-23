package dk.kb.kac.common;

import org.apache.parquet.example.data.Group;
import org.apache.parquet.io.api.Binary;
import org.apache.parquet.schema.MessageType;
import org.apache.parquet.schema.PrimitiveType;
import org.apache.parquet.schema.Types;

import static org.apache.parquet.schema.OriginalType.UTF8;
import static org.apache.parquet.schema.PrimitiveType.PrimitiveTypeName.BINARY;
import static org.apache.parquet.schema.PrimitiveType.PrimitiveTypeName.INT64;

public class ParquetSchema {
    
    
    public static MessageType getSchema() {
    
        PrimitiveType name = requiredString("name");
        PrimitiveType txt = requiredString("txt");
        PrimitiveType xml = requiredString("xml");
        PrimitiveType jpg = requiredBinary("jpg");
        
        MessageType message = Types.buildMessage()
                                   .addFields(name, txt, xml, jpg)
                                   .named("example");
        return message;
        
    }
    
    public static class Page {
        private String name;
        private String txt;
        private String xml;
        private Binary jpg;
    
        public Page(String name, String txt, String xml, Binary jpg) {
            this.name = name;
            this.txt = txt;
            this.xml = xml;
            this.jpg = jpg;
        }
    
        public String getName() {
            return name;
        }
    
        public String getTxt() {
            return txt;
        }
    
        public String getXml() {
            return xml;
        }
    
        public Binary getJpg() {
            return jpg;
        }
    }
    
    public static Page parse_record(Group group){
        String name = group.getString("name", 0);
        String txt = group.getString("txt", 0);
        String xml = group.getString("xml", 0);
        Binary jpg = group.getBinary("jpg", 0);
        return new Page(name,txt,xml        ,jpg);
    
    }
    
    private static PrimitiveType optionalString(String name) {
        return Types.optional(BINARY).as(UTF8).named(name);
    }
    
    private static PrimitiveType requiredBinary(String name) {
        return Types.required(BINARY).named(name);
    }
    
    private static PrimitiveType requiredLong(String name) {
        return Types.required(INT64).named(name);
    }
    
    private static PrimitiveType requiredString(String name) {
        return Types.required(BINARY).as(UTF8).named(name);
    }
    
    public static String getStringRepresentation(MessageType type) {
        StringBuilder bigNumberStringBuilder = new StringBuilder();
        type.writeToStringBuilder(bigNumberStringBuilder, "");
        return type.toString();
    }
    
}
