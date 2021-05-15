export class InvalidExpressionError extends Error {
  constructor(message: string) {
    super(message)
    Object.setPrototypeOf(this, InvalidExpressionError.prototype)
  }
}
