# Copyright 1996-1998 by Steven McDougall.  This module is free
# software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Set::IntSpan;

use strict;
use 5.004;
use vars qw($VERSION @ISA @EXPORT_OK);
use integer;

require Exporter;

$VERSION   = '1.07';
@ISA       = qw(Exporter);
@EXPORT_OK = qw(grep_set map_set);

$Set::IntSpan::Empty_String = '-';


sub new
{
    my($this, $set_spec) = @_;
   
    my $class = ref($this) || $this;
    my $set   = bless { }, $class;
    $set->{empty_string} = \$Set::IntSpan::Empty_String;
    $set->copy($set_spec)
}


sub valid
{
    my($this, $run_list) = @_;
    my $class = ref($this) || $this;
    my $set   = new $class;

    eval { $set->_copy_run_list($run_list) };
    $@ ? 0 : 1
}


sub copy
{
    my($set, $set_spec) = @_;

  SWITCH: 
    {
	defined $set_spec            or  $set->_copy_empty   (         ), last;
	ref     $set_spec            or  $set->_copy_run_list($set_spec), last;
	ref     $set_spec eq 'ARRAY' and $set->_copy_array   ($set_spec), last;
				         $set->_copy_set     ($set_spec)      ;
    }    

    $set
}


sub _copy_empty			# makes $set the empty set
{
    my $set = shift;
    
    $set->{negInf} = 0;
    $set->{posInf} = 0;
    $set->{edges } = [];
}


sub _copy_array			# copies an array into a set
{
    my($set, $array) = @_;

    $set->{negInf} = 0;
    $set->{posInf} = 0;

    my @edges;
    for my $element (sort { $a <=> $b } @$array)
    {
	next if @edges and $edges[-1] == $element; # skip duplicates

	if (@edges and $edges[-1] == $element-1)
	{
	    $edges[-1] = $element;
	}
	else
	{
	    push @edges, $element-1, $element;
	}
    }
    
    $set->{edges} = \@edges
}


sub _copy_set			# copies one set to another
{
    my($dest, $src) = @_;
    
    $dest->{negInf} =     $src->{negInf};
    $dest->{posInf} =     $src->{posInf};
    $dest->{edges } = [ @{$src->{edges }} ];
}


sub _copy_run_list		# parses a run list
{
    my($set, $runList) = @_;

    $set->_copy_empty;

    $runList =~ s/\s|_//g;
    return if $runList eq '-';	# empty set
  
    my($first, $last) = (1, 0);	# verifies order of infinite runs

    my @edges;
    for my $run (split(/,/ , $runList))
    {
    	die "Set::IntSpan::_copy_run_list: Bad order: $runList\n" if $last;
    	
      RUN: 
    	{	    	
	    $run =~ /^ (-?\d+) $/x and do
	    {
		push(@edges, $1-1, $1);
		last RUN;
	    };

	    $run =~ /^ (-?\d+) - (-?\d+) $/x and do
	    {
		die "Set::IntSpan::_copy_run_list: Bad order: $runList\n" 
		    if $1 > $2;
		push(@edges, $1-1, $2);
		last RUN;
	    };

	    $run =~ /^ \( - (-?\d+) $/x and do
	    {
		die "Set::IntSpan::_copy_run_list: Bad order: $runList\n" 
		    unless $first;
		$set->{negInf} = 1;
		push @edges, $1;
		last RUN;
	    };

	    $run =~ /^ (-?\d+) - \) $/x and do
	    {
		push @edges, $1-1;
		$set->{posInf} = 1;
		$last = 1;
		last RUN;
	    };

	    $run =~ /^ \( - \) $/x and do
	    {
		die "Set::IntSpan::_copy_run_list: Bad order: $runList\n" 
		    unless $first;
		$last = 1;
		$set->{negInf} = 1;
		$set->{posInf} = 1;
		last RUN;
	    };

	    die "Set::IntSpan::_copy_run_list: Bad syntax: $runList\n";
	}

	$first = 0;
    }
    
    $set->{edges} = [ @edges ];
    
    $set->_cleanup or 
	die "Set::IntSpan::_copy_run_list: Bad order: $runList\n";
}


# check for overlapping runs
# delete duplicate edges
sub _cleanup
{
    my $set = shift;
    my $edges = $set->{edges};	

    my $i=0;
    while ($i < $#$edges)
    {
	my $cmp = $$edges[$i] <=> $$edges[$i+1];
	{
	    $cmp == -1 and $i++                  , last;
	    $cmp ==  0 and splice(@$edges, $i, 2), last;
	    $cmp ==  1 and return 0;
	}
    }
    
    1
}


sub run_list
{
    my $set = shift;
    
    $set->empty and return ${$set->{empty_string}};

    my @edges = @{$set->{edges}};
    my @runs;

    $set->{negInf} and unshift @edges, '(';
    $set->{posInf} and push    @edges, ')';

    while(@edges)
    {
	my($lower, $upper) = splice @edges, 0, 2;

	if ($lower ne '(' and $upper ne ')' and $lower+1==$upper)
	{
	    push @runs, $upper;
	}
	else
	{
	    $lower ne '(' and $lower++;
	    push @runs, "$lower-$upper";
	}
    }
    
    join(',', @runs)
}


sub elements
{
    my $set = shift;

    ($set->{negInf} or $set->{posInf}) and 
	die "Set::IntSpan::elements: infinite set\n";

    my @elements;
    my @edges = @{$set->{edges}};
    while (@edges)
    {
	my($lower, $upper) = splice(@edges, 0, 2);
	push @elements, $lower+1 .. $upper;
    }

    wantarray ? @elements : \@elements
}


sub _real_set		# converts a set specification into a set
{
    my($set, $set_spec) = @_;

    (defined $set_spec and ref $set_spec and ref $set_spec ne 'ARRAY') ?
	$set_spec : 
	$set->new($set_spec)
}


sub union
{
    my($a, $set_spec) = @_;
    my $b = $a->_real_set($set_spec);
    my $s = $a->new;

    $s->{negInf} = $a->{negInf} || $b->{negInf};
    
    my $eA = $a->{edges};
    my $eB = $b->{edges};
    my $eS = $s->{edges};
    
    my $inA = $a->{negInf};
    my $inB = $b->{negInf};
    
    my $iA = 0;
    my $iB = 0;

    while ($iA<@$eA and $iB<@$eB)
    {
	my $xA = $$eA[$iA];
	my $xB = $$eB[$iB];
	
	if ($xA < $xB)
	{
	    $iA++;
	    $inA = ! $inA;
	    not $inB and push(@$eS, $xA);
	}
	elsif ($xB < $xA)
	{
	    $iB++;
	    $inB = ! $inB;
	    not $inA and push(@$eS, $xB);
	}
	else
	{
	    $iA++;
	    $iB++;
	    $inA = ! $inA;
	    $inB = ! $inB;
	    $inA == $inB and push(@$eS, $xA);
	}
    }

    $iA < @$eA and ! $inB and push(@$eS, @$eA[$iA..$#$eA]);
    $iB < @$eB and ! $inA and push(@$eS, @$eB[$iB..$#$eB]);

    $s->{posInf} = $a->{posInf} || $b->{posInf};
    $s
}


sub intersect
{
    my($a, $set_spec) = @_;
    my $b = $a->_real_set($set_spec);
    my $s = $a->new;

    $s->{negInf} = $a->{negInf} && $b->{negInf};
    
    my $eA = $a->{edges};
    my $eB = $b->{edges};
    my $eS = $s->{edges};
    
    my $inA = $a->{negInf};
    my $inB = $b->{negInf};
    
    my $iA = 0;
    my $iB = 0;

    while ($iA<@$eA and $iB<@$eB)
    {
	my $xA = $$eA[$iA];
	my $xB = $$eB[$iB];
	
	if ($xA < $xB)
	{
	    $iA++;
	    $inA = ! $inA;
	    $inB and push(@$eS, $xA);
	}
	elsif ($xB < $xA)
	{
	    $iB++;
	    $inB = ! $inB;
	    $inA and push(@$eS, $xB);
	}
	else
	{
	    $iA++;
	    $iB++;
	    $inA = ! $inA;
	    $inB = ! $inB;
	    $inA == $inB and push(@$eS, $xA);
	}
    }

    $iA < @$eA and $inB and push(@$eS, @$eA[$iA..$#$eA]);
    $iB < @$eB and $inA and push(@$eS, @$eB[$iB..$#$eB]);

    $s->{posInf} = $a->{posInf} && $b->{posInf};
    $s
}


sub diff
{
    my($a, $set_spec) = @_;
    my $b = $a->_real_set($set_spec);
    my $s = $a->new;

    $s->{negInf} = $a->{negInf} && ! $b->{negInf};
    
    my $eA = $a->{edges};
    my $eB = $b->{edges};
    my $eS = $s->{edges};
    
    my $inA = $a->{negInf};
    my $inB = $b->{negInf};
    
    my $iA = 0;
    my $iB = 0;

    while ($iA<@$eA and $iB<@$eB)
    {
	my $xA = $$eA[$iA];
	my $xB = $$eB[$iB];
	
	if ($xA < $xB)
	{
	    $iA++;
	    $inA = ! $inA;
	    not $inB and push(@$eS, $xA);
	}
	elsif ($xB < $xA)
	{
	    $iB++;
	    $inB = ! $inB;
	    $inA and push(@$eS, $xB);
	}
	else
	{
	    $iA++;
	    $iB++;
	    $inA = ! $inA;
	    $inB = ! $inB;
	    $inA != $inB and push(@$eS, $xA);
	}
    }

    $iA < @$eA and not $inB and push(@$eS, @$eA[$iA..$#$eA]);
    $iB < @$eB and     $inA and push(@$eS, @$eB[$iB..$#$eB]);

    $s->{posInf} = $a->{posInf} && ! $b->{posInf};
    $s
}


sub xor
{
    my($a, $set_spec) = @_;
    my $b = $a->_real_set($set_spec);
    my $s = $a->new;

    $s->{negInf} = $a->{negInf} ^ $b->{negInf};
    
    my $eA = $a->{edges};
    my $eB = $b->{edges};
    my $eS = $s->{edges};
    
    my $iA = 0;
    my $iB = 0;

    while ($iA<@$eA and $iB<@$eB)
    {
	my $xA = $$eA[$iA];
	my $xB = $$eB[$iB];
	
	if ($xA < $xB)
	{
	    $iA++;
	    push(@$eS, $xA);
	}
	elsif ($xB < $xA)
	{
	    $iB++;
	    push(@$eS, $xB);
	}
	else
	{
	    $iA++;
	    $iB++;
	}
    }

    $iA < @$eA and push(@$eS, @$eA[$iA..$#$eA]);
    $iB < @$eB and push(@$eS, @$eB[$iB..$#$eB]);

    $s->{posInf} = $a->{posInf} ^ $b->{posInf};
    $s
}


sub complement
{
    my $set = shift;
    my $comp = $set->new($set);
    
    $comp->{negInf} = ! $comp->{negInf};
    $comp->{posInf} = ! $comp->{posInf};
    $comp
}


sub superset
{
    my($a, $set_spec) = @_;
    my $b = $a->_real_set($set_spec);

    $b->diff($a)->empty
}


sub subset
{
    my($a, $b) = @_;

    $a->diff($b)->empty
}


sub equal
{
    my($a, $set_spec) = @_;
    my $b = $a->_real_set($set_spec);
    
    $a->{negInf} == $b->{negInf} or return 0;
    $a->{posInf} == $b->{posInf} or return 0;
    
    my $aEdge = $a->{edges};
    my $bEdge = $b->{edges};
    @$aEdge == @$bEdge or return 0;
    
    for (my $i=0; $i<@$aEdge; $i++)
    {
	$$aEdge[$i] == $$bEdge[$i] or return 0;
    }
    
    1
}


sub equivalent
{
    my($a, $set_spec) = @_;
    my $b = $a->_real_set($set_spec);

    $a->cardinality == $b->cardinality
}


sub cardinality
{
    my $set = shift;

    ($set->{negInf} or $set->{posInf}) and return -1;

    my $cardinality = 0;
    my @edges = @{$set->{edges}};
    while (@edges)
    {
	my $lower = shift @edges;
	my $upper = shift @edges;
	$cardinality += $upper - $lower;
    }

    $cardinality
}


sub empty
{
    my $set = shift;

    not $set->{negInf} and not @{$set->{edges}} and not $set->{posInf}
}


sub finite
{
    my $set = shift;
    
    not $set->{negInf} and not $set->{posInf}
}


sub neg_inf { shift->{negInf} }
sub pos_inf { shift->{posInf} }


sub infinite
{
    my $set = shift;
    
    $set->{negInf} or $set->{posInf}
}


sub universal
{
    my $set = shift;
    
    $set->{negInf} and not @{$set->{edges}} and $set->{posInf}
}


sub member
{
    my($set, $n) = @_;
    
    my $inSet = $set->{negInf};
    my $edge  = $set->{edges};
    
    for (my $i=0; $i<@$edge; $i++)
    {
	if ($inSet)
	{
	    return 1 if $n <= $$edge[$i];
	    $inSet = 0;
	}
	else
	{
	    return 0 if $n <= $$edge[$i];
	    $inSet = 1;
	}
    }
    
    $inSet
}


sub insert
{
    my($set, $n) = @_;
    defined $n or return;

    my $inSet = $set->{negInf};
    my $edge = $set->{edges};

    my $i;
    for ($i=0; $i<@$edge; $i++)
    {
	if ($inSet)
	{
	    $n <= $edge->[$i] and return;
	    $inSet = 0;
	}
	else
	{
	    $n <= $edge->[$i] and last;
	    $inSet = 1;
	}
    }

    $inSet and return;

    my $lGap = $i==0      || $n-1 - $edge->[$i-1];
    my $rGap = $i==@$edge || $edge->[$i] - $n;
    
    if    (    $lGap and     $rGap) { splice @$edge, $i, 0, $n-1, $n }
    elsif (not $lGap and     $rGap) { $edge->[$i-1]++                }
    elsif (    $lGap and not $rGap) { $edge->[$i  ]--                }
    else                            { splice @$edge, $i-1, 2         }
}


sub remove
{
    my($set, $n) = @_;
    defined $n or return;

    my $inSet = $set->{negInf};
    my $edge  = $set->{edges};

    my $i;
    for ($i=0; $i<@$edge; $i++)
    {
	if ($inSet)
	{
	    last if $n <= $$edge[$i];
	    $inSet = 0;
	}
	else
	{
	    return if $n <= $$edge[$i];
	    $inSet = 1;
	}
    }

    return unless $inSet;

    splice @{$set->{edges}}, $i, 0, $n-1, $n;
    $set->_cleanup;
}


sub min
{
    my $set = shift;

    $set->empty   and return undef;
    $set->neg_inf and return undef;
    $set->{edges}->[0]+1
}


sub max
{
    my $set = shift;

    $set->empty   and return undef;
    $set->pos_inf and return undef;
    $set->{edges}->[-1]
}


sub grep_set(&$)
{
    my($block, $set) = @_;

    return undef if $set->{negInf} or $set->{posInf};

    my @edges     = @{$set->{edges}};
    my @sub_edges = ();

    while (@edges)
    {
	my($lower, $upper) = splice(@edges, 0, 2);

	for (my $i=$lower+1; $i<=$upper; $i++)
	{
	    local $_ = $i;
	    &$block() or next;

	    if (@sub_edges and $sub_edges[-1] == $i-1)
	    {
		$sub_edges[-1] = $i;
	    }
	    else
	    {
		push @sub_edges, $i-1, $i;
	    }
	}
    }

    my $sub_set = $set->new;
    $sub_set->{edges} = \@sub_edges;
    $sub_set
}    


sub map_set(&$)
{
    my($block, $set) = @_;

    return undef if $set->{negInf} or $set->{posInf};

    my $map_set = $set->new;

    my @edges = @{$set->{edges}};
    while (@edges)
    {
	my($lower, $upper) = splice(@edges, 0, 2);

	my $domain;
	for ($domain=$lower+1; $domain<=$upper; $domain++)
	{
	    local $_ = $domain;

	    my $range;
	    for $range (&$block())
	    {
		$map_set->insert($range);
	    }
	}
    }

    $map_set
}    


sub first($)
{
    my $set   = shift;

    $set->{iterator} = $set->min;
    $set->{run}[0]   = 0;
    $set->{run}[1]   = $#{$set->{edges}} ? 1 : undef;

    $set->{iterator}
}


sub last($)
{
    my $set = shift;

    my $lastEdge     = $#{$set->{edges}};
    $set->{iterator} = $set->max;
    $set->{run}[0]   = $lastEdge ? $lastEdge-1 : undef;
    $set->{run}[1]   = $lastEdge;

    $set->{iterator}
}


sub start($$)
{
    my($set, $start) = @_;

    $set->{iterator} = undef;
    defined $start or return undef;

    my $inSet = $set->{negInf};
    my $edges = $set->{edges};
    
    for (my $i=0; $i<@$edges; $i++)
    {
	if ($inSet)
	{
	    if ($start <= $$edges[$i])
	    {
		$set->{iterator} = $start;
		$set->{run}[0] = $i ? $i-1 : undef;
		$set->{run}[1] = $i;
		return $start;
	    }
	    $inSet = 0;
	}
	else
	{
	    if ($start <= $$edges[$i])
	    {
		return undef;
	    }
	    $inSet = 1;
	}
    }
    
    if ($inSet)
    {
	$set->{iterator} = $start;
	$set->{run}[0]   = @$edges? $#$edges: undef;
	$set->{run}[1]   = undef;
    }

    $set->{iterator}
}


sub current($) { shift->{iterator} }


sub next($)
{
    my $set = shift;

    defined $set->{iterator} or return $set->first;

    my $run1 = $set->{run}[1];
    defined $run1 or return ++$set->{iterator};

    my $edges = $set->{edges};
    $set->{iterator} < $edges->[$run1] and return ++$set->{iterator};

    if    ($run1 < $#$edges-1)
    {
	my $run0         = $run1 + 1;
	$set->{run}      = [$run0, $run0+1];
	$set->{iterator} = $edges->[$run0]+1;
    }
    elsif ($run1 < $#$edges)
    {
	my $run0         = $run1 + 1;
	$set->{run}      = [$run0, undef];
	$set->{iterator} = $edges->[$run0]+1;
    }
    else
    {
	$set->{iterator} = undef;
    }

    $set->{iterator}
}


sub prev($)
{
    my $set = shift;

    defined $set->{iterator} or return $set->last;

    my $run0 = $set->{run}[0];
    defined $run0 or return --$set->{iterator};

    my $edges = $set->{edges};
    $set->{iterator} > $edges->[$run0]+1 and return --$set->{iterator};

    if    ($run0 > 1)
    {
	my $run1         = $run0 - 1;
	$set->{run}      = [$run1-1, $run1];
	$set->{iterator} = $edges->[$run1];
    }
    elsif ($run0 > 0)
    {
	my $run1         = $run0 - 1;
	$set->{run}      = [undef, $run1];
	$set->{iterator} = $edges->[$run1];
    }
    else
    {
	$set->{iterator} = undef;
    }

    $set->{iterator}
}


1

__END__

=head1 NAME

Set::IntSpan - Manages sets of integers

=head1 SYNOPSIS

  use Set::IntSpan qw(grep_set map_set);
  
  $Set::IntSpan::Empty_String = $string;
  
  $set    = new   Set::IntSpan $set_spec;
  $valid  = valid Set::IntSpan $run_list;
  $set    = copy  $set $set_spec;
  
  $run_list = run_list $set;
  @elements = elements $set;
  
  $u_set = union      $set $set_spec;
  $i_set = intersect  $set $set_spec;
  $x_set = xor        $set $set_spec;
  $d_set = diff       $set $set_spec;
  $c_set = complement $set;
  
  equal      $set $set_spec;
  equivalent $set $set_spec;
  superset   $set $set_spec;
  subset     $set $set_spec;
  
  $n = cardinality $set;
  
  empty      $set;
  finite     $set;
  neg_inf    $set;
  pos_inf    $set;
  infinite   $set;
  universal  $set;
  
  member     $set $n;
  insert     $set $n;
  remove     $set $n;
  
  $min = min $set;
  $max = max $set;
  
  $subset = grep_set { ... } $set;
  $mapset = map_set  { ... } $set;
  
  for ($element=$set->first; defined $element; $element=$set->next) { ... }
  for ($element=$set->last ; defined $element; $element=$set->prev) { ... }
  
  $element = $set->start($n);
  $element = $set->current;

=head1 REQUIRES

Perl 5.004, Exporter

=head1 EXPORTS

=head2 C<@EXPORT>

Nothing

=head2 C<@EXPORT_OK>

C<grep_set>, C<map_set>

=head1 DESCRIPTION

C<Set::IntSpan> manages sets of integers.
It is optimized for sets that have long runs of consecutive integers.
These arise, for example, in .newsrc files, which maintain lists of articles:

  alt.foo: 1-21,28,31
  alt.bar: 1-14192,14194,14196-14221

Sets are stored internally in a run-length coded form.
This provides for both compact storage and efficient computation.
In particular, 
set operations can be performed directly on the encoded representation.

C<Set::IntSpan> is designed to manage finite sets.
However, it can also represent some simple infinite sets, such as 
{x | x>n}.
This allows operations involving complements to be carried out consistently, 
without having to worry about the actual value of INT_MAX on your machine.

=head1 SET SPECIFICATIONS

Many of the methods take a I<set specification>.  
There are four kinds of set specifications.

=head2 Empty

If a set specification is omitted, then the empty set is assumed.
Thus, 

  $set = new Set::IntSpan;

creates a new, empty set.  Similarly,

  copy $set;

removes all elements from $set.

=head2 Object reference

If an object reference is given, it is taken to be a C<Set::IntSpan> object.

=head2 Array reference

If an array reference is given, 
then the elements of the array are taken to be the elements of the set.  
The array may contain duplicate elements.
The elements of the array may be in any order.

=head2 Run list

If a string is given, it is taken to be a I<run list>.
A run list specifies a set using a syntax similar to that in newsrc files.

A run list is a comma-separated list of I<runs>.
Each run specifies a set of consecutive integers.
The set is the union of all the runs.

Runs may be written in any of several forms.

=over 8

=head2 Finite forms

=item n

{ n }

=item a-b

{x | a<=x && x<=b}

=back

=head2 Infinite forms

=over 8

=item (-n

{x | x<=n}

=item n-)

{x | x>=n}

=item (-)

The set of all integers

=back

=head2 Empty forms

The empty set is consistently written as '' (the null string).
It is also denoted by the special form '-' (a single dash).

=head2 Restrictions

The runs in a run list must be disjoint, 
and must be listed in increasing order.

Valid characters in a run list are 0-9, '(', ')', '-' and ','.
White space and underscore (_) are ignored.
Other characters are not allowed.

=head2 Examples

=over 15

=item S< >-

{ }

=item S< >1

{ 1 }

=item S< >1-2

{ 1, 2 }

=item S< >-5--1

{ -5, -4, -3, -2, -1 }

=item S< >(-)

the integers

=item S< >(--1

the negative integers

=item S< >1-3, 4, 18-21

{ 1, 2, 3, 4, 18, 19, 20, 21 }

=back

=head1 ITERATORS

Each set has a single I<iterator>, 
which is shared by all calls to 
C<first>, C<last>, C<start>, C<next>, C<prev>, and C<current>.
At all times,
the iterator is either an element of the set,
or C<undef>.

C<first>, C<last>, and C<start> set the iterator;
C<next>, and C<prev> move it;
and C<current> returns it.
Calls to these methods may be freely intermixed.

Using C<next> and C<prev>, 
a single loop can move both forwards and backwards through a set.
Using C<start>, a loop can iterate over portions of an infinite set.

=head1 METHODS

=head2 Creation

=over 4

=item I<$set> = C<new> C<Set::IntSpan> I<$set_spec>

Creates and returns a C<Set::IntSpan> object.
The initial contents of the set are given by I<$set_spec>.

=item I<$ok> = C<valid> C<Set::IntSpan> I<$run_list>

Returns true if I<$run_list> is a valid run list.
Otherwise, returns false and leaves an error message in $@.

=item I<$set> = C<copy> I<$set> I<$set_spec>

Copies I<$set_spec> into I<$set>.
The previous contents of I<$set> are lost.
For convenience, C<copy> returns I<$set>.

=item I<$run_list> = C<run_list> I<$set>

Returns a run list that represents I<$set>.
The run list will not contain white space.
I<$set> is not affected.

By default, the empty set is formatted as '-'; 
a different string may be specified in C<$Set::IntSpan::Empty_String>.

=item I<@elements> = C<elements> I<$set>

Returns an array containing the elements of I<$set>.
The elements will be sorted in numerical order.
In scalar context, returns an array reference.
I<$set> is not affected.

=back

=head2 Set operations

=over 4

=item I<$u_set> = C<union> I<$set> I<$set_spec>

Returns the set of integers in either I<$set> or I<$set_spec>.

=item I<$i_set> = C<intersect> I<$set> I<$set_spec>

Returns the set of integers in both I<$set> and I<$set_spec>.

=item I<$x_set> = C<xor> I<$set> I<$set_spec>

Returns the set of integers in I<$set> or I<$set_spec>, 
but not both.

=item I<$d_set> = C<diff> I<$set> I<$set_spec>

Returns the set of integers in I<$set> but not in I<$set_spec>.

=item I<$c_set> = C<complement> I<$set>

Returns the set of integers that are not in I<$set>.

=back

For all set operations, 
a new C<Set::IntSpan> object is created and returned.  
The operands are not affected.

=head2 Comparison

=over 4

=item C<equal> I<$set> I<$set_spec>

Returns true iff I<$set> and I<$set_spec> contain the same elements.

=item C<equivalent> I<$set> I<$set_spec>

Returns true iff I<$set> and I<$set_spec> contain the same number of elements.
All infinite sets are equivalent.

=item C<superset> I<$set> I<$set_spec>

Returns true iff I<$set> is a superset of I<$set_spec>.

=item C<subset> I<$set> I<$set_spec>

Returns true iff I<$set> is a subset of I<$set_spec>.

=back

=head2 Cardinality

=over 4

=item I<$n> = C<cardinality> I<$set>

Returns the number of elements in I<$set>.
Returns -1 for infinite sets.

=item C<empty> I<$set>

Returns true iff I<$set> is empty.

=item C<finite> I<$set>

Returns true iff I<$set> is finite.

=item C<neg_inf> I<$set>

Returns true iff I<$set> contains {x | x<n} for some n.

=item C<pos_inf> I<$set>

Returns true iff I<$set> contains {x | x>n} for some n.

=item C<infinite> I<$set>

Returns true iff I<$set> is infinite.

=item universal I<$set>

Returns true iff I<$set> contains all integers.

=back

=head2 Membership

=over 4

=item C<member> I<$set> I<$n>

Returns true iff the integer I<$n> is a member of I<$set>.

=item C<insert> I<$set> I<$n>

Inserts the integer I<$n> into I<$set>.
Does nothing if I<$n> is already a member of I<$set>.

=item C<remove> I<$set> I<$n>

Removes the integer I<$n> from I<$set>.
Does nothing if I<$n> is not a member of I<$set>.

=back

=head2 Extrema

=over 4

=item C<min> I<$set>

Returns the smallest element of I<$set>, 
or C<undef> if there is none.

=item C<max> I<$set>

Returns the largest element of I<$set>,
or C<undef> if there is none.

=back

=head2 Iterators

=over 4

=item I<$set>->C<first>

Sets the iterator for I<$set> to the smallest element of I<$set>.
If there is no smallest element,
sets the iterator to C<undef>.
Returns the iterator.

=item I<$set>->C<last>

Sets the iterator for I<$set> to the largest element of I<$set>.
If there is no largest element,
sets the iterator to C<undef>.
Returns the iterator.

=item I<$set>->C<start>(I<$n>)

Sets the iterator for I<$set> to I<$n>.
If I<$n> is not an element of I<$set>,
sets the iterator to C<undef>.
Returns the iterator.

=item I<$set>->C<next>

Sets the iterator for I<$set> to the next element of I<$set>.
If there is no next element,
sets the iterator to C<undef>.
Returns the iterator.

C<next> will return C<undef> only once;
the next call to C<next> will reset the iterator to 
the smallest element of I<$set>.

=item I<$set>->C<prev>

Sets the iterator for I<$set> to the previous element of I<$set>.
If there is no previous element,
sets the iterator to C<undef>.
Returns the iterator.

C<prev> will return C<undef> only once;
the next call to C<prev> will reset the iterator to 
the largest element of I<$set>.

=item I<$set>->C<current>

Returns the iterator for I<$set>.

=back

=head1 FUNCTIONS

=over 4

=item I<$sub_set> = C<grep_set> { ... } I<$set>

Evaluates the BLOCK for each integer in I<$set> 
(locally setting C<$_> to each integer)
and returns a C<Set::IntSpan> object containing those integers
for which the BLOCK returns TRUE.

Returns C<undef> if I<$set> is infinite.

=item I<$map_set> = C<map_set> { ... } I<$set>

Evaluates the BLOCK for each integer in I<$set> 
(locally setting C<$_> to each integer) 
and returns a C<Set::IntSpan> object containg
all the integers returned as results of all those evaluations.

Evaluates the BLOCK in list context, 
so each element of I<$set> may produce zero, one,
or more elements in the returned set.

Returns C<undef> if I<$set> is infinite.

=back

=head1 CLASS VARIABLES

=over 4

=item C<$Set::IntSpan::Empty_String>

C<$Set::IntSpan::Empty_String> contains the string that is returned when
C<run_list> is called on the empty set.
C<$Empty_String> is initially '-'; 
alternatively, it may be set to ''.
Other values should be avoided,
to ensure that C<run_list> always returns a valid run list.

C<run_list> accesses C<$Empty_String> through a reference
stored in I<$set>->{C<empty_string>}.
Subclasses that wish to override the value of C<$Empty_String> can
reassign this reference.

=back

=head1 DIAGNOSTICS

Any method (except C<valid>) will C<die> if it is passed an invalid run list.

=over 4

=item C<Set::IntSpan::_copy_run_list: Bad syntax:> I<$runList>

(F) I<$run_list> has bad syntax

=item C<Set::IntSpan::_copy_run_list: Bad order:> I<$runList>

(F) I<$run_list> has overlapping runs or runs that are out of order.

=item C<Set::IntSpan::elements: infinite set>

(F) An infinte set was passed to C<elements>.

=item Out of memory!

(X) C<elements> I<$set> can generate an "Out of memory!" 
message on sufficiently large finite sets.

=back

=head1 NOTES

=head2 Traps

Beware of forms like

  union $set [1..5];

This passes an element of @set to union, 
which is probably not what you want.
To force interpretation of $set and [1..5] as separate arguments, 
use forms like

    union $set +[1..5];

or

    $set->union([1..5]);

=head2 Cardinality

You cannot use the obvious comparison routine

  { $a->cardinality <=> $b->cardinality }

to sort sets by size, 
because C<cardinality> returns -1 for infinte sets.
(All the non-negative integers were taken. Sorry.)

Instead, you have to write something like

  {  my $a_card = $a->cardinality;
     my $b_card = $b->cardinality;
     
     $a_card == $b_card and return  0;
     $a_card <  0       and return  1;
     $b_card <  0       and return -1;
     $a_card <=> $b_card                }

=head2 grep_set and map_set

C<grep_set> and C<map_set> make it easy to construct
sets for which the internal representation used by C<Set::IntSpan>
is I<not> small. Consider:

  $billion = new Set::IntSpan '0-1_000_000_000';   # OK
  $odd     = grep_set { $_ & 1 } $billion;         # trouble
  $even    = map_set  { $_ * 2 } $billion;         # double trouble

=head2 Error handling

There are two common approaches to error handling:
exceptions and return codes.
There seems to be some religion on the topic,
so C<Set::IntSpan> provides support for both.

To catch exceptions, protect method calls with an eval:

    $run_list = <STDIN>;
    eval { $set = new Set::IntSpan $run_list };
    $@ and print "$@: try again\n";

To check return codes, use an appropriate method call to validate arguments:

    $run_list = <STDIN>;
    if (valid Set::IntSpan $run_list) 
       { $set = new Set::IntSpan $run_list }
    else
       { print "$@ try again\n" }

Similarly, use C<finite> to protect calls to C<elements>:

    finite $set and @elements = elements $set;

Calling C<elements> on a large, finite set can generate an "Out of
memory!" message, which cannot (easily) be trapped.
Applications that must retain control after an error can use C<intersect> to 
protect calls to C<elements>:

    @elements = elements { intersect $set "-1_000_000 - 1_000_000" };

or check the size of $set first:

    finite $set and cardinality $set < 2_000_000 and @elements = elements $set;

=head2 Limitations

Although C<Set::IntSpan> can represent some infinite sets, 
it does I<not> perform infinite-precision arithmetic.  
Therefore, 
finite elements are restricted to the range of integers on your machine.

=head2 Roots

The sets implemented here are based on a Macintosh data structure called 
a I<region>.
See Inside Macintosh for more information.

=head1 AUTHOR

Steven McDougall, swmcd@world.std.com

=head1 COPYRIGHT

Copyright 1996-1998 by Steven McDougall. This module is free
software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
