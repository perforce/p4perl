[![Support](https://img.shields.io/badge/Support-Official-green.svg)](mailto:support@perforce.com)

# p4perl
## Overview
P4Perl is a wrapper for the P4 C++ API in Perl.

P4Perl is a Perl module that provides an object-oriented API to Helix Core server. Using P4Perl is faster than using the command-line interface in scripts, because multiple command can be executed on a single connection, and because it returns Helix server responses as Perl hashes and arrays.

## Requirements
#### Helix Core Compatibility
P4Perl 2019.1 officially supports Helix Core Server 2019.1. 
	  
#### API Compatibility
The 2019.1 release of P4Perl supports the 2019.1 Helix Core API (P4API). Older releases of the Helix Core API may work but are no longer supported.

#### Perl Compatibility
The 2019.1 release of P4Perl is supported building from source with Perl 5.28 and versions back to 5.14. 
The P4Perl 32-bit Windows installer requires Perl 5.28 32-bit. 
The P4Perl 64-bit Windows installer requires Perl 5.28 64-bit.

#### OpenSSL Compatibility
To build P4Perl with encrypted communication support, you must use the version of OpenSSL that Perforce C/C++ API has been built against. Running P4Perl linked to an older library will fail with the error:
	
"SSL library must be at least version 1.0.1."

The 2016.1 release of P4Perl is supported with OpenSSL 1.0.1.

For detailed compatibility, please check the following table:

##### Perforce C/C++ API Version | OpenSSL Release
	============================================
		     2012.1                | 	1.0.0
		     2012.2 - 2014.2       | 	1.0.1g+
		     2016.1                | 	1.0.1k+
		     2018.2                |    1.0.2
		     2019.1                |    1.0.2

#### Platform Compatibility

While P4Perl is generally portable, this release is certified only on the following platforms:

* Linux kernel 2.6+ (glibc 2.12+) for Intel(x86, x86_64)
* Windows 8 for Intel(x86, x64)
* Windows 8.1 for Intel(x86, x64)
* Windows 10 for Intel(x86, x64)
* Windows 2008 for Intel(x86, x64)
* Windows 2012 for Intel(x64)
* Windows 2016 for Intel(x64)
* Apple OS X 10.10+ for Intel(x86_64)

#### Compiler Compatibility

To build P4Perl from source, you must use a version of Perl that has been compiled with the same compiler used to build the Perforce C++ API. For most platforms, use gcc/g++.

Attempting to use a different compiler or a different version of the compiler can cause linker errors due to differences in name handling between compilers. 

#### Compatibility with Previous Releases

P4Perl 2019.1 is backwards-compatible with all previous releases from Perforce Software.

## Documentation
Official documentation is located on the [Perforce website](https://www.perforce.com/manuals/p4perl/Content/P4Perl/Home-p4perl.html)

## Support
P4Perl is officially supported by Perforce.
Pull requests will be managed by Perforce's engineering teams. We will do our best to acknowledge these in a timely manner based on available capacity.  
Issues will not be managed on GitHub. All issues should be recorded via [Perforce's standard support process](https://www.perforce.com/support/request-support). 
