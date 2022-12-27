package dk.kb.kac.common;

import org.apache.commons.io.IOUtils;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FSDataInputStream;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.BytesWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.InputSplit;
import org.apache.hadoop.mapreduce.JobContext;
import org.apache.hadoop.mapreduce.RecordReader;
import org.apache.hadoop.mapreduce.TaskAttemptContext;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.FileSplit;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.List;

public class WholeFileInputFormat extends FileInputFormat<Text, BytesWritable> {
    
    private static final Logger log = LoggerFactory.getLogger(WholeFileInputFormat.class);
    
    public WholeFileInputFormat() {
    }

    @Override protected boolean isSplitable(JobContext context, Path filename) {
        return false;
    }

    @Override public RecordReader<Text, BytesWritable> createRecordReader(InputSplit split, TaskAttemptContext context)
            throws IOException, InterruptedException {
        return new WholeFileRecordReader();
    }

    @Override public List<InputSplit> getSplits(JobContext job) throws IOException {
        return super.getSplits(job);
    }

    public static class WholeFileRecordReader extends RecordReader<Text, BytesWritable> {
        private static final Logger log = LoggerFactory.getLogger(WholeFileRecordReader.class);

        private Path path;
        private int length;

        private Configuration conf;

        private boolean processed = false;
        private BytesWritable value = new BytesWritable();
        private Text key;


        @Override public void initialize(InputSplit split, TaskAttemptContext context)
                throws IOException, InterruptedException {
            this.conf = context.getConfiguration();
            if (split instanceof FileSplit) {
                FileSplit fileSplit = (FileSplit) split;
                path = fileSplit.getPath();
                if (fileSplit.getLength() > Integer.MAX_VALUE){
                    throw new IOException("File '"+fileSplit.getPath()+"' size "+fileSplit.getLength()+" greater than max value "+Integer.MAX_VALUE);
                } else {
                    length = (int) fileSplit.getLength();
                }
                log.info("Read file {} to length={}",path.toString(),length);

            } else {
                throw new IOException("Not a file split");
            }
        }

        @Override
        public boolean nextKeyValue() throws IOException, InterruptedException {
            if (!processed) {
                key = new Text(path.toString());

                log.info("reading file {} of length={}", path.toString(),length);
                try(FileSystem fs = path.getFileSystem(conf);
                        FSDataInputStream in = fs.open(path);) {
                    
                    value.setSize(length);
                    
                    IOUtils.readFully(in, value.getBytes(), 0, length);
                    log.info("Read {} bytes from file {}", value.getLength(), path.toString());
                }
                processed = true;
                return true;
            } else {
                key = null;
                value = null;
                return false;
            }
        }


        @Override public Text getCurrentKey() throws IOException, InterruptedException {
            return key;
        }

        @Override public BytesWritable getCurrentValue() throws IOException, InterruptedException {
            return value;
        }

        @Override public float getProgress() throws IOException, InterruptedException {
            return processed ? 1.0f : 0.0f;
        }

        @Override public void close() throws IOException {

        }
    }
}
