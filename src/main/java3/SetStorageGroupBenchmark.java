package org.apache.iotdb.db.service;

import java.time.ZoneId;
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

public class SetStorageGroupBenchmark {
  private static ZoneId zoneId = ZoneId.systemDefault();
  private static LogicalGenerator generator = new LogicalGenerator(zoneId);

  @Param({"1", "5", "10", "20", "50", "100", "500", "1000", "2000", "3000", "4000", "5000", "20000"})
  private int pathNodeNumber;

  @Param({"7", "50"})
  private int pathNodeLength;

  @Benchmark
  public Operator select() throws ParseException, QueryProcessException, MetadataException {
    AstNode astTree = ParseGenerator
        .generateAST(getSql(pathNodeLength, pathNodeNumber));
    AstNode astTree2 = ParseUtils.findRootNonNullToken(astTree);
    return generator.getLogicalPlan(astTree2);
  }

  public static void main(String[] args) throws RunnerException {
    Options opt = new OptionsBuilder()
        .include(SetStorageGroupBenchmark.class.getSimpleName())
        .forks(1)
        .warmupIterations(10)
        .measurementIterations(10)
        .build();
    new Runner(opt).run();
  }

  private static String getSql(int pathNodeLength, int pathNodeNumber) {
    return "set storage group to "
        + timeSeriesPath(pathNodeLength, pathNodeNumber)
        ;
  }

  private static String timeSeriesPath(int pathNodeLength, int pathNodeNumber) {
    StringBuilder prefixPath = new StringBuilder();
    prefixPath.append("root");
    for(int j = 0; j < pathNodeNumber; j++) {
      prefixPath.append(".");
      prefixPath.append(randomNodeName(pathNodeLength));
    }
    return prefixPath.toString();
  }

  private static String randomNodeName(int length) {
    Random random = new Random();
    int choice = random.nextInt(2);
    switch (choice) {
      case 0:
        return getRandomString2(length);
      case 1:
        return Integer.toString(random.nextInt((int) Math.pow(10, length)));
    }
    return null;
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