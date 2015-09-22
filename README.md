# NAME

LWP::UserAgent::Mockable - Permits recording, and later playing back of LWP requests.

# VERSION

Version 1.10

# SYNOPSIS

    # setup env vars to control behaviour, allowing them to be
    # overridden from command line.  In current case, do before
    # loading module, so will be actioned on.

    BEGIN {
        $ENV{ LWP_UA_MOCK } ||= 'playback';
        $ENV{ LWP_UA_MOCK_FILE } ||= 'lwp-mock.out';
    }

    use LWP;
    use LWP::UserAgent::Mockable;

    # setup a callback when recording, to allow modifying the response

    LWP::UserAgent::Mockable->set_record_callback( sub {
        my ( $request, $response ) = @_;

        print "GOT REQUEST TO: " . $request->uri;
        $response->content( lc( $response->content ) );

        return $response;
    } );

    # perform LWP request, as normal

    my $ua = LWP::UserAgent->new;
    my $res = $ua->get( "http://gmail.com" );
    print $res->content;

    # when the LWP work is done, inform LWP::UserAgent::Mockable
    # that we're finished.  Will trigger any behaviour specific to
    # the action being done, such as saving the recorded session.

    END {
        # END block ensures cleanup if script dies early
        LWP::UserAgent::Mockable->finished;
    }

# DESCRIPTION

This module adds session record and playback options for LWP requests, whilst
trying to introduce as little clutter as necessary.

When in record mode, all LWP requests and responses will be captured in-memory,
until the finished method is called, at which point they will then be written
out to a file.  In playback mode, LWP responses are short-circuited, to instead
return the responses that were previously dumped out.  If neither of the above
actions are requested, this module does nothing, so LWP requests are handled as
normal.

Most of the control of this module is done via environment variables, both to
control the action being done (LWP\_UA\_MOCK env var, allowed values being
'record', 'playback', 'passthrough' (the default) ), and to control the file
that is used for storing or replaying the responses (LWP\_UA\_MOCK\_FILE env var,
not used for 'passthrough' mode).

The only mandatory change to incorporate this module is to call the 'finished'
method, to indicate that LWP processing is completed.  Other than that, LWP
handling can be done as-normal.

As the initial impetus for this module was to allow mocking of external HTTP
calls within unittests, a couple of optional callback (one for each action of
the valid action types), to allow for custom handling of responses, or to modify
the response that is returned back to the client (this is useful for simulating
the requested system being down, or when playing back, to modify the mocked
response to reflect expected dynamic content).

## Methods

As there is only a singleton instance of LWP::UserAgent::Mockable, all methods
are class methods.

- finished() - required

    Informs LWP::UserAgent::Mockable that no further requests are expected, and
    allow it to do any post-processing that is required.

    When in 'record' mode, this will cause the playback file (controlled by
    LWP\_UA\_MOCK\_FILE env var) to be created.  When in 'playback' mode, this will
    issue a warning if there is still additional mocked responses that haven't been
    returned.

- set\_record\_callback( <sub {}> ) - optional
- set\_playback\_callback( <sub {}> ) - optional

    These optional methods allow custom callbacks to be inserted, when performing
    the relevant actions.  The callback will be invoked for each LWP request, AFTER
    the request has been actioned (see set\_record\_pre\_callback for a method o
    short-circuiting the LWP fetch).  They will be passed in 2 parameters, an
    [HTTP::Request](https://metacpan.org/pod/HTTP::Request) and an [HTTP::Response](https://metacpan.org/pod/HTTP::Response) object.  For the record callback
    (which is used for both 'record' and 'passthrough' mode) the request will be
    the [HTTP::Request](https://metacpan.org/pod/HTTP::Request) object used to perform the request, and the response the
    [HTTP::Response](https://metacpan.org/pod/HTTP::Response) result from that.  In playback mode, the request will be the
    [HTTP::Request](https://metacpan.org/pod/HTTP::Request) object used to perform the request, and the response the mocked
    response object.

    When the callbacks are being used, they're expected to return an
    [HTTP::Response](https://metacpan.org/pod/HTTP::Response) object, which will be treated as the actual reply from the
    call being made.  Failure to do do will result in a fatal error being raised.

    To clear a callback, call the relevant method, passing in no argument.

- set\_record\_pre\_callback( <sub {}> ) - optional

    This callback is similar to set\_record\_callback, except that it will
    short-circuit the actual fetching of the remote URL.  Only a single parameter
    is passed through to this callback, that being the [HTTP::Request](https://metacpan.org/pod/HTTP::Request) object.
    It's expected to construct an return an [HTTP::Response](https://metacpan.org/pod/HTTP::Response) object (or subclass
    thereof).  Should anything other than an [HTTP::Response](https://metacpan.org/pod/HTTP::Response) subclass be
    returned, a fatal error will be raised.

    This callback will be invoked for both 'record' and 'passthrough' modes.
    Note that there is no analagous callback for 'playback' mode.

    To clear the callback, pass in no argument.

- set\_playback\_validation\_callback( <sub {}> ) - optional

    This callback allows validation of the received request.  It receives two
    parameters, both [HTTP::Request](https://metacpan.org/pod/HTTP::Request)s, the first being the actual request made,
    the second being the mocked request that was received when recording a session.
    It's up to the callback to do any validation that it wants, and to perform any
    action that is warranted.

    As with other callbacks, to clear, pass in no argument to the method.

- reset( <action>, <file> ) - optional

    Reset the state of mocker, allowing the action and file operation on to change.
    Will also reset all callbacks.  Note that this will raise an error, if called
    whilst there are outstanding requests, and the **finished** method hasn't been
    called.

# CAVEATS

The playback file generated by this is not encrypted in any manner.  As it's
only using [Storable](https://metacpan.org/pod/Storable) to dump the file, it's easy to get at the data contained
within, even if the requests are going to HTTPS sites.  Treat the playback file
as if it were the original data, security-wise.

# SEE ALSO

- [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) - The class being mocked.
- [Test::LWP::UserAgent](https://metacpan.org/pod/Test::LWP::UserAgent)
- [HTTP::Request](https://metacpan.org/pod/HTTP::Request)
- [HTTP::Response](https://metacpan.org/pod/HTTP::Response)

# AUTHOR

Mark Morgan, `<makk384@gmail.com>`

# CONTRIBUTORS

Michael Jemmeson, `<michael.jemmeson@cpan.org>`

Kit Peters, `<popefelix@cpan.org>`

Mohammad S. Anwar, `<mohammad.anwar at yahoo.com>`

# SUPPORT

## Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at [https://github.com/mjemmeson/LWP-UserAgent-Mockable/issues](https://github.com/mjemmeson/LWP-UserAgent-Mockable/issues).
You will be notified automatically of any progress on your issue.

## Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

[https://github.com/mjemmeson/LWP-UserAgent-Mockable](https://github.com/mjemmeson/LWP-UserAgent-Mockable)

    git clone git://github.com/mjemmeson/LWP-UserAgent-Mockable.git

# COPYRIGHT & LICENSE

Copyright 2009 Mark Morgan, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
