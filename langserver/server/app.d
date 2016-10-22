/*
 * This auto-generated skeleton file illustrates how to build a server. If you
 * intend to customize it, you should edit a copy with another file name to 
 * avoid overwriting it when running the generator again.
 */
module Language_server;

import std.stdio;
import thrift.codegen.processor;
import thrift.protocol.binary;
import thrift.server.simple;
import thrift.server.transport.socket;
import thrift.transport.buffered;
import thrift.util.hashset;

import Language;
import interpreter_types;

interface Language {
  string Interprete(string code);

  enum methodMeta = [
    TMethodMeta(`Interprete`, 
      [TParamMeta(`code`, 1)]
    )
  ];
}

class LanguageHandler : Language {
  this() {
    // Your initialization goes here.
  }

  string Interprete(string code) {
    
    try {
      auto context = new Context();
      context.enterFunction();
      auto runtime = new IntrinsicRuntime();
      auto tokenizer = new Tokenizer(new DCharReader(source));

      foreach (statement; tokenizer.parseStatements()) {
        statement.evaluate(context, runtime);
      }
    } catch (SourceException exception) {
      writeln(exception.getErrorInformation(source).toString());
    }

    writeln("Interprete called");
    return typeof(return).init;
  }

}

void main() {
  auto protocolFactory = new TBinaryProtocolFactory!();
  auto processor = new TServiceProcessor!Language(new LanguageHandler);
  auto serverTransport = new TServerSocket(9090);
  auto transportFactory = new TBufferedTransportFactory;
  auto server = new TSimpleServer(
    processor, serverTransport, transportFactory, protocolFactory);
  server.serve();
}
