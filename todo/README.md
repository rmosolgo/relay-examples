# GraphQL-Ruby Relay example

This example has been modified to use a Ruby server (see `server.rb`). Additionally, the server uses a custom ID type.

-----

# Relay TodoMVC

## Installation

```
yarn
```

## Running

Set up generated files:

```
yarn update-schema
yarn build
```

Start a local server:

```
yarn start
```

## Developing

Any changes you make to files in the `js/` directory will cause the server to
automatically rebuild the app and refresh your browser.

If at any time you make changes to `data/schema.js`, stop the server,
regenerate `data/schema.graphql`, and restart the server:

```
yarn update-schema
yarn build
yarn start
```

## License

    This file provided by Facebook is for non-commercial testing and evaluation
    purposes only.  Facebook reserves all rights not expressly granted.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
    FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
    ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
