package dk.kb.kac.files2parquet_job;

import dk.kb.kac.common.NewspaperFile;
import dk.kb.kac.common.ParquetSchema;
import dk.kb.kac.common.WholeFileInputFormat;
import org.apache.commons.io.FilenameUtils;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.conf.Configured;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.BytesWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.util.Tool;
import org.apache.hadoop.util.ToolRunner;
import org.apache.parquet.example.data.Group;
import org.apache.parquet.hadoop.ParquetOutputFormat;
import org.apache.parquet.hadoop.example.ExampleOutputFormat;
import org.apache.parquet.hadoop.example.GroupWriteSupport;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.time.Duration;

public class ParquetWriteMapReduceJob extends Configured implements Tool {
    
    
    public static void main(String[] args) throws Exception {
        int ret = ToolRunner.run(new ParquetWriteMapReduceJob(), args);
        System.exit(ret);
    }
    
    
    @Override
    public int run(String[] args) throws Exception {
        
        Job job = Job.getInstance(getConf());
        Configuration conf = job.getConfiguration();
        //TO fix org.apache.hadoop.yarn.exceptions.YarnRuntimeException: java.io.IOException: Split metadata size exceeded 10000000.
        conf.set("mapreduce.job.split.metainfo.maxsize", "-1");
    
        job.setJobName(getClass().getName());
        job.setJarByClass(getClass());
        
        //set the InputFormat of the job to our InputFormat
        job.setInputFormatClass(WholeFileInputFormat.class);
        
        WholeFileInputFormat.addInputPath(job, new Path(args[1]));
        WholeFileInputFormat.setInputDirRecursive(job, true);
        
        job.setMapperClass(Mapper.class);
        
        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(NewspaperFile.class);
        
        job.setNumReduceTasks(32);
        job.setReducerClass(ParquetWriterReducer.class);
        job.setOutputKeyClass(Void.class);
        job.setOutputValueClass(Group.class);
        
        //Parquet options
        conf.set(ParquetOutputFormat.BLOCK_SIZE, Integer.toString(128 * 1024 * 1024));
        conf.set(ParquetOutputFormat.COMPRESSION, "GZIP");
        
        //Parquet output format
        job.setOutputFormatClass(ExampleOutputFormat.class);
        ParquetOutputFormat.setOutputPath(job, new Path(args[0]));
        GroupWriteSupport.setSchema(ParquetSchema.getSchema(), conf);
        ParquetOutputFormat.setWriteSupportClass(job, GroupWriteSupport.class);
        
        job.getConfiguration().set("mapreduce.task.timeout", "" + Duration.ofMinutes(30).toMillis());
        
        return job.waitForCompletion(true) ? 0 : 1;
    }
    
    public static class Mapper extends org.apache.hadoop.mapreduce.Mapper<Text, BytesWritable, Text, NewspaperFile> {
        
        private static final Logger log = LoggerFactory.getLogger(Mapper.class);
        
        public Mapper() {
        }
        
        @Override
        protected void map(Text key, BytesWritable value, Context context) throws IOException, InterruptedException {
            Path path = new Path(key.toString());
            log.info("Found path={}", path);
            String name = FilenameUtils.getBaseName(path.toString());
            String type = FilenameUtils.getExtension(path.toString());
            log.info("Calculated name={}, type={} for value-length={}", name, type, value.getLength());
            context.write(new Text(name), new NewspaperFile(new Text(type), value));
        }
    }
}
