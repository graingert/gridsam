// prints out prime numbers between the 2 integers given
class Primes
{
  public static void main(String args[])
  {
    if(args.length == 2) // process the parameters
    {
      try {
        Primes p = new Primes(new Integer(args[0]).intValue(), new Integer(args[1]).intValue());
      } catch (Exception e) {
        System.out.println("Primes: Error while processing primes between '" + args[0] + "' and '" + args[1] + "'.");
      }
    }
    else
      System.out.println("Primes: Wrong number of parameters given.");
  }

  public Primes(int min, int max) // iterate through the range
  {
    for(int i=min; i<=max; ++i)
    {
      if(isPrime(i))
        System.out.println(i);
    }
  }

  static public boolean isPrime(int number) // is this number a prime?
  {
    if(number==1 || number==2) // 1 and 2 are primes
      return true;

    if((number % 2)==0) // an even number
      return false;

    for(int i=2; i<number; i++)
    {
      if((number % i)==0)
        return false;
    }

    return true;
  }
}
