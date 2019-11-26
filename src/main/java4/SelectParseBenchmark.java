import java.time.ZoneId;
import java.util.Random;
import java.util.concurrent.TimeUnit;
import org.apache.iotdb.db.qp.logical.Operator;
import org.apache.iotdb.db.qp.strategy.ParseDriver;
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
/*
Select Parse BenchMark;
 */
public class SelectParseBenchmark {

  private static ZoneId zoneId = ZoneId.systemDefault();
  private static ParseDriver driver = new ParseDriver();

  @Param({"1", "5", "10", "20"})
  private int suffixNodeNumber;

  @Param({"1", "5", "10", "20", "50", "100", "500", "1000", "2000", "3000", "4000", "5000", "20000"})
  private int prefixNodeNumber;

  @Param({"7", "50"})
  private int suffixNodeLength;

  @Param({"7", "50"})
  private int prefixNodeLength;

  @Param({"1", "5", "10", "20"})
  private int number;

  @Benchmark
  public Operator select() {
    return driver.parse(getSql(prefixNodeNumber,prefixNodeLength, suffixNodeNumber, suffixNodeLength, number), zoneId);
  }

  public static void main(String[] args) throws RunnerException {
    Options opt = new OptionsBuilder()
        .include(SelectParseBenchmark.class.getSimpleName())
        .forks(1)
        .warmupIterations(10)
        .measurementIterations(10)
        .build();
    new Runner(opt).run();
  }

  private static String getSql(int prefixNodeNumber, int prefixNodeLength, int suffixNodeNumber, int suffixNodeLength, int number) {
    StringBuilder selectStatement = new StringBuilder();
    selectStatement.append("select ");
    //selectElements
    selectStatement.append(randomSuffixPath(suffixNodeNumber, suffixNodeLength));
    for(int i = 1; i < number; i++) {
      selectStatement.append(",");
      selectStatement.append(randomSuffixPath(suffixNodeNumber, suffixNodeLength));
    }
    //fromClause
    selectStatement.append(" from ");
    selectStatement.append(randomPrefixPath(prefixNodeNumber, prefixNodeLength));
    for(int i = 1; i < number; i++) {
      selectStatement.append(",");
      selectStatement.append(randomPrefixPath(prefixNodeNumber, prefixNodeLength));
    }

    //whereClause
    selectStatement.append(" where time > 2017-11-03T06:00:00 and temperature > 20");

    return selectStatement.toString();
  }

//  private static String randomPredicate() {
//    StringBuilder predicate = new StringBuilder();
//    Random random = new Random();
//    int choice = random.nextInt(2);
//    switch (choice) {
//      case 0 :
//        predicate.append(randomPrefixPath());
//        break;
//      case 1:
//        predicate.append(randomSuffixPath());
//        break;
//    }
//    predicate.append(" ").append(randomComparison()).append(" ");
//    predicate.append(randomConstant());
//    return predicate.toString();
//  }

//  private static String randomConstant() {
//    Random random = new Random();
//    int choice = random.nextInt(5);
//    switch (choice) {
//      case 0:
//        return getRandomString2(random.nextInt(100)+6);
//      case 1:
//        return String.format("%6.3e", 10000000 * random.nextDouble());
//      case 2:
//        return Integer.toString(random.nextInt(10000000));
//      case 3:
//        return "'" + getRandomString2(random.nextInt(100)+6) + "'";
//      case 4:
//        return "\"" + getRandomString2(random.nextInt(100)+6) + "\"";
//    }
//    return null;
//  }

  private static String randomPrefixPath(int prefixNodeNumber, int prefixNodeLength) {
    StringBuilder prefixPath = new StringBuilder();
    prefixPath.append("root");
    for(int j = 0; j < prefixNodeNumber; j++) {
      prefixPath.append(".");
      prefixPath.append(randomNodeName(prefixNodeLength));
    }
    return prefixPath.toString();
  }

  private static String randomSuffixPath(int suffixNodeNumber, int suffixNodeLength) {
    StringBuilder suffixPath = new StringBuilder();
    suffixPath.append(randomNodeName(suffixNodeLength));
    for(int j = 1; j < suffixNodeNumber ; j++) {
      suffixPath.append(".");
      suffixPath.append(randomNodeName(suffixNodeLength));
    }
    return suffixPath.toString();
  }

//  private static String randomBinaryOp() {
//    Random random = new Random();
//    int choice = random.nextInt(2);
//    switch(choice) {
//      case 0:
//        return "or";
//      case 1:
//        return  "and";
//    }
//    return null;
//  }

//  private static String randomComparison() {
//    Random random = new Random();
//    int choice = random.nextInt(6);
//    switch(choice) {
//      case 0:
//        return "=";
//      case 1:
//        return ">";
//      case 2:
//        return "<";
//      case 3:
//        return ">=";
//      case 4:
//        return "<=";
//      case 5:
//        return "!=";
//    }
//    return null;
//  }

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
