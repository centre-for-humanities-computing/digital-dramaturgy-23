package dk.kb.kac.files2parquet_job;

import dk.kb.kac.common.NewspaperFile;
import dk.kb.kac.common.ParquetSchema;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.parquet.example.data.Group;
import org.apache.parquet.example.data.simple.SimpleGroupFactory;
import org.apache.parquet.io.api.Binary;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

public class ParquetWriterReducer extends
                                  Reducer<Text, NewspaperFile, Void, Group> {
    
    public static final SimpleGroupFactory factory = new SimpleGroupFactory(ParquetSchema.getSchema());
    private static final Logger log = LoggerFactory.getLogger(ParquetWriterReducer.class);
    
    
    @Override
    protected void reduce(Text name, Iterable<NewspaperFile> files, Context context)
            throws IOException, InterruptedException {
    
        Map<String, byte[]> fields = new HashMap<>();
        
        for (NewspaperFile next : files) {
            String type = next.getType().toString();
            byte[] contents = next.getContents().copyBytes();
            fields.put(type, contents);
            log.info("Getting type '{}' for name {} with contents={}", type, name.toString(), contents.length);
        }
        
        //The return record
        Group parquet_record = factory.newGroup();
        
        //The input keys are output, for easier merging back with corpus.
        parquet_record.add("name", name.toString());
    
        byte[] txts = fields.getOrDefault("txt", new byte[0]);
        log.info("Found txt with length={}",txts.length);
        String txt = new String(txts);
        parquet_record.add("txt", txt);
    
        byte[] xmls = fields.getOrDefault("xml", new byte[0]);
        log.info("Found xml with length={}",xmls.length);
        String xml = new String(xmls);
        parquet_record.add("xml", xml);
    
        byte[] jpgs = fields.getOrDefault("jpg", new byte[0]);
        log.info("Found jpg with length={}",jpgs.length);
        Binary jpg = Binary.fromConstantByteArray(jpgs);
        parquet_record.add("jpg", jpg);
        
        //Output the record
        context.write(null, parquet_record);
    }
}
