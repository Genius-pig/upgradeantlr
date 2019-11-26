package org.apache.iotdb.db.service;

import java.text.SimpleDateFormat;
import java.time.ZoneId;
import java.util.Date;
import java.util.Random;
import java.util.concurrent.TimeUnit;
import org.apache.iotdb.db.exception.metadata.MetadataException;
import org.apache.iotdb.db.exception.query.QueryProcessException;
import org.apache.iotdb.db.qp.logical.Operator;
import org.apache.iotdb.db.qp.strategy.LogicalGenerator;
import org.apache.iotdb.db.sql.ParseGenerator;
import org.apache.iotdb.db.sql.parse.AstNode;
import org.apache.iotdb.db.sql.parse.ParseException;
import org.apache.iotdb.db.sql.parse.ParseUtils;
import org.openjdk.jmh.annotations.Benchmark;
import org.openjdk.jmh.annotations.BenchmarkMode;
import org.openjdk.jmh.annotations.Mode;
import org.openjdk.jmh.annotations.OutputTimeUnit;
import org.openjdk.jmh.annotations.Param;
import org.openjdk.jmh.annotations.Scope;
import org.openjdk.jmh.annotations.State;
import org.openjdk.jmh.runner.Runner;
import org.openjdk.jmh.runner.RunnerException;
import org.openjdk.jmh.runner.options.Options;
import org.openjdk.jmh.runner.options.OptionsBuilder;

@State(Scope.Thread)
@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.MICROSECONDS)

public class QueryParseBenchmark {

  private static ZoneId zoneId = ZoneId.systemDefault();
  private static LogicalGenerator generator = new LogicalGenerator(zoneId);

  @Param({"4", "6", "8", "10", "20", "30", "40", "50"})
  private int pathLevelNumber;

  @Param({"1", "5", "10", "20", "50", "100", "500", "1000", "2000", "3000", "4000", "5000", "20000"})
  private int sensorNumber;

  @Param({"7", "50"})
  private int sensorLength;

  @Param({"7", "50"})
  private int pathNameLength;

  @Benchmark
  public Operator insert() throws QueryProcessException, MetadataException, ParseException {
    AstNode astTree = ParseGenerator
        .generateAST(getSql(pathLevelNumber, sensorNumber, sensorLength, pathNameLength));
    AstNode astTree2 = ParseUtils.findRootNonNullToken(astTree);
    return generator.getLogicalPlan(astTree2);
  }

  public static void main(String[] args) throws RunnerException {
    Options opt = new OptionsBuilder()
        .include(QueryParseBenchmark.class.getSimpleName())
        .forks(1)
        .warmupIterations(10)
        .measurementIterations(10)
        .build();
    new Runner(opt).run();
  }

  private static String getSql(int pathLevelNumber, int sensorNumber, int sensorLength, int pathNameLength) {
    StringBuilder timeseriesPath =new StringBuilder();
    timeseriesPath.append("root");
    for(int i = 0; i < pathLevelNumber-1; i++) {
      timeseriesPath.append(".");
      timeseriesPath.append(randomNodeNameWithoutStar(pathNameLength));
    }

    StringBuilder insertColumnSpec = new StringBuilder();
    insertColumnSpec.append("(");
    insertColumnSpec.append("timestamp");
    for(int i = 0; i < sensorNumber; i++) {
      insertColumnSpec.append(",");
      insertColumnSpec.append(randomNodeNameWithoutStar(sensorLength));
    }
    insertColumnSpec.append(")");

    StringBuilder insertValuesSpec = new StringBuilder();
    insertValuesSpec.append("(");
    Date date = randomDate("0-1-1","9999-12-31");
    String time = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(date);
    insertValuesSpec.append(time);
    for(int i = 0; i < sensorNumber; i++) {
      insertValuesSpec.append(",");
      insertValuesSpec.append(randomConstant());
    }
    insertValuesSpec.append(")");

    return "insert into "
        + timeseriesPath.toString()
        + insertColumnSpec.toString()
        + " values"
        + insertValuesSpec.toString();
  }

  private static String randomNodeNameWithoutStar(int length) {
    Random random = new Random();
    int choice = random.nextInt(2);
    switch (choice) {
      case 0:
        return Integer.toString(random.nextInt((int)Math.pow(10, length)));
      case 1:
        return getRandomString2(length);
    }
    return null;
  }

  private static String randomConstant() {
    Random random = new Random();
    int choice = random.nextInt(6);
    switch (choice) {
      case 0:
        Date date = randomDate("0-1-1","9999-12-31");
        return new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(date);
      case 1:
        return getRandomString2(7);
      case 2:
        return String.format("%6.3e", 10000000 * random.nextDouble());
      case 3:
        return Integer.toString(random.nextInt(10000000));
      case 4:
        return "'" + getRandomString2(7) + "'";
      case 5:
        return "\"" + getRandomString2(7) + "\"";
    }
    return null;
  }

  private static Date randomDate(String beginDate, String endDate){
    try {
      SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd");
      Date start = format.parse(beginDate);
      Date end = format.parse(endDate);

      if(start.getTime() >= end.getTime()){
        return null;
      }
      long date = random(start.getTime(),end.getTime());
      return new Date(date);
    } catch (Exception e) {
      e.printStackTrace();
    }
    return null;
  }

  private static long random(long begin,long end){
    long rtn = begin + (long)(Math.random() * (end - begin));
    if(rtn == begin || rtn == end){
      return random(begin,end);
    }
    return rtn;
  }


  private static String getRandomString2(int length){
    Random random=new Random();
    StringBuilder sb =new StringBuilder();
    int first = random.nextInt(2);
    long firstResult;
    switch(first) {
      case 0:
        firstResult = Math.round(Math.random()*25+65);
        sb.append((char) firstResult);
        break;
      case 1:
        firstResult = Math.round(Math.random()*25+97);
        sb.append((char) firstResult);
        break;
    }
    for(int i=1;i<length;i++){
      int number=random.nextInt(3);
      long result;
      switch(number){
        case 0:
          result= Math.round(Math.random()*25+65);
          sb.append((char) result);
          break;
        case 1:
          result= Math.round(Math.random()*25+97);
          sb.append((char) result);
          break;
        case 2:
          sb.append(new Random().nextInt(10));
          break;
      }
    }
    return sb.toString();
  }
}
