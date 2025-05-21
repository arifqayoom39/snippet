import 'package:fpdart/fpdart.dart';
import 'package:snippet/core/failure.dart';

typedef FutureEither<T> = Future<Either<Failure, T>>;
typedef FutureEitherVoid = FutureEither<void>;
