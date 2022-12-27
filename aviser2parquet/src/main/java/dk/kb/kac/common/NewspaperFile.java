package dk.kb.kac.common;

import org.apache.hadoop.io.BytesWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.io.Writable;

import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

public class NewspaperFile implements Writable {
    private final Text type;
    private final BytesWritable contents;
    
    
    public NewspaperFile(Text type, BytesWritable contents) {
        this.type = type;
        this.contents = contents;
    }
    
    public NewspaperFile() {
        this.type = new Text();
        this.contents = new BytesWritable();
    }
    
    @Override
    public void write(DataOutput out) throws IOException {
        type.write(out);
        contents.write(out);
    }
    
    @Override
    public void readFields(DataInput in) throws IOException {
        type.readFields(in);
        contents.readFields(in);
    }
    
    public Text getType() {
        return type;
    }
    
    public BytesWritable getContents() {
        return contents;
    }
}
