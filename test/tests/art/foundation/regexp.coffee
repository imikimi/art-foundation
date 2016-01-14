{assert} = require 'art.foundation/src/art/dev_tools/test/art_chai'
Foundation = require "art.foundation"

{emailRegexp, domainRegexp, urlProtocolRegexp, urlPathRegexp, urlQueryRegexp, urlRegexp} = Foundation

suite "Art.Foundation.Regexp", ->
  test "emailRegexp", ->
    assert.eq "shanebdavis@gmail.com".match(emailRegexp), ["shanebdavis@gmail.com", "shanebdavis", "gmail.com"]
    assert.eq "shanebdavis@www.gmail.com".match(emailRegexp), ["shanebdavis@www.gmail.com", "shanebdavis", "www.gmail.com"]

  test "domainRegexp successes", ->
    assert.eq "gmail.com".match(domainRegexp), ["gmail.com"]
    assert.eq "gmail0.com".match(domainRegexp), ["gmail0.com"]
    assert.eq "gmail.evilplanet".match(domainRegexp), ["gmail.evilplanet"]
    assert.eq "g-mail.com".match(domainRegexp), ["g-mail.com"]
    assert.eq "g.mail.com".match(domainRegexp), ["g.mail.com"]
    assert.eq "g.m-ail.com".match(domainRegexp), ["g.m-ail.com"]

  test "domainRegexp failures", ->
    assert.eq !!"gmail.c".match(domainRegexp), false
    assert.eq !!"gmail.c0m".match(domainRegexp), false
    assert.eq !!".com".match(domainRegexp), false
    assert.eq !!"com".match(domainRegexp), false

  test "urlProtocolRegexp successes", ->
    assert.eq "https://".match(urlProtocolRegexp), ["https://"]
    assert.eq "http://".match(urlProtocolRegexp), ["http://"]
    assert.eq "HTTP://".match(urlProtocolRegexp), ["HTTP://"]
    assert.eq "ftp://".match(urlProtocolRegexp), ["ftp://"]

  test "urlProtocolRegexp failures", ->
    assert.eq !!"http".match(urlProtocolRegexp), false
    assert.eq "http0://".match(urlProtocolRegexp), ["http0://"]
    assert.eq !!"http:/".match(urlProtocolRegexp), false
    assert.eq !!"://".match(urlProtocolRegexp), false

  test "urlPathRegexp successes", ->
    assert.eq "/".match(urlPathRegexp), ["/"]
    assert.eq "//".match(urlPathRegexp), ["//"]
    assert.eq "/foo".match(urlPathRegexp), ["/foo"]
    assert.eq "/foo0".match(urlPathRegexp), ["/foo0"]
    assert.eq "/foo/bar".match(urlPathRegexp), ["/foo/bar"]
    assert.eq "/foo_bar".match(urlPathRegexp), ["/foo_bar"]
    assert.eq "/foo-Bar".match(urlPathRegexp), ["/foo-Bar"]
    assert.eq "/foo%20Bar".match(urlPathRegexp), ["/foo%20Bar"]
    assert.eq "/foo+Bar".match(urlPathRegexp), ["/foo+Bar"]

  test "urlPathRegexp failures", ->
    assert.eq !!"/foo Bar".match(urlPathRegexp), false
    assert.eq !!"/foo%2zBar".match(urlPathRegexp), false

  test "urlQueryRegexp successes", ->
    assert.eq "foo".match(urlQueryRegexp), ["foo"]
    assert.eq "foo0".match(urlQueryRegexp), ["foo0"]
    assert.eq "foo=bar".match(urlQueryRegexp), ["foo=bar"]
    assert.eq "foo-bar".match(urlQueryRegexp), ["foo-bar"]
    assert.eq "foo+bar".match(urlQueryRegexp), ["foo+bar"]
    assert.eq "foo_bar".match(urlQueryRegexp), ["foo_bar"]
    assert.eq "foo%20bar".match(urlQueryRegexp), ["foo%20bar"]

  test "urlRegexp successes", ->
    assert.eq "http://foo.com".match(urlRegexp), ["http://foo.com", "http://", "foo.com", undefined, undefined]
    assert.eq "http://foo.com/here".match(urlRegexp), ["http://foo.com/here", "http://", "foo.com", "/here", undefined]
    assert.eq "http://foo.com?this=that".match(urlRegexp), ["http://foo.com?this=that", "http://", "foo.com", undefined, "this=that"]
    assert.eq "http://foo.com?".match(urlRegexp), ["http://foo.com?", "http://", "foo.com", undefined, ""]
    assert.eq "http://foo.com/?this=that".match(urlRegexp), ["http://foo.com/?this=that", "http://", "foo.com", "/", "this=that"]
    assert.eq "http://foo.com/here?this=that".match(urlRegexp), ["http://foo.com/here?this=that", "http://", "foo.com", "/here", "this=that"]