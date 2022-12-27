package dk.kb.kac.for_each_file_job;

import dk.kb.kac.common.ParquetSchema;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.conf.Configured;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.output.TextOutputFormat;
import org.apache.hadoop.util.Tool;
import org.apache.hadoop.util.ToolRunner;
import org.apache.parquet.example.data.Group;
import org.apache.parquet.hadoop.ParquetInputFormat;
import org.apache.parquet.hadoop.example.GroupReadSupport;

import java.io.IOException;

public class ParquetReadMapReduceJob extends Configured implements Tool {
    
    
    public static void main(String[] args) throws Exception {
        int ret = ToolRunner.run(new ParquetReadMapReduceJob(), args);
        System.exit(ret);
    }
    
    
    @Override
    public int run(String[] args) throws Exception {
        
        Job job = Job.getInstance(getConf());
        Configuration conf = job.getConfiguration();
        
        job.setJobName(getClass().getName());
        job.setJarByClass(getClass());
        
        //set the InputFormat of the job to parquet
        job.setInputFormatClass(ParquetInputFormat.class);
        ParquetInputFormat.addInputPath(job, new Path(args[0]));
    
        ParquetInputFormat.setReadSupportClass(job, GroupReadSupport.class);
        conf.set(GroupReadSupport.PARQUET_READ_SCHEMA,ParquetSchema.getStringRepresentation(ParquetSchema.getSchema()));

        
        job.setMapperClass(Mapper.class);
        
        job.setMapOutputKeyClass(Void.class);
        job.setMapOutputValueClass(Text.class);
        TextOutputFormat.setOutputPath(job, new Path(args[1]));
        
    
    
        job.setNumReduceTasks(0);
        
        return job.waitForCompletion(true) ? 0 : 1;
    }
    
    
    
    /** Stupid mapper that just parses the parquet record and outputs the name **/
    public static class Mapper extends org.apache.hadoop.mapreduce.Mapper<LongWritable, Group, NullWritable, Text> {
    
        @Override
        protected void map(LongWritable key, Group value, Context context) throws IOException, InterruptedException {
            
    
            ParquetSchema.Page parsed = ParquetSchema.parse_record(value);
    
            NullWritable outKey = NullWritable.get();
            context.write(outKey,new Text(parsed.getName()));
        
        }
    }
}
