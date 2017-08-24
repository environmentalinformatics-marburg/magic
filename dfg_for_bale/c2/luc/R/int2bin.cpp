#include <Rcpp.h>
using namespace Rcpp;

#include <iostream>
#include <bitset>

// [[Rcpp::export]]
String int2bin(unsigned int x) {
  std::string binary = std::bitset<16>(x).to_string(); //to binary
  // std::cout << binary << "\n";
  // 
  // unsigned long decimal = std::bitset<8>(binary).to_ulong();
  // std::cout<<decimal<<"\n";
  return binary;
}

// [[Rcpp::export]]
CharacterVector vec2bin(IntegerVector x) {
  int n = x.size();
  CharacterVector out(n);
  
  for (int i = 0; i < n; i++) {
    out[i] = int2bin(x[i]);
  }
  
  return out;
}

// inspired by https://stackoverflow.com/questions/22746429/c-decimal-to-binary-converting