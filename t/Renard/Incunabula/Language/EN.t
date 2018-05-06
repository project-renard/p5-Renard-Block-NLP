#!/usr/bin/env perl

use Test::Most;

use lib 't/lib';
use Renard::Incunabula::Devel::TestHelper;

use Renard::Incunabula::Common::Setup;
use Renard::Incunabula::Format::PDF::Document;
use Renard::Incunabula::Language::EN;
use Function::Parameters;

my $pdf_ref_path = try {
	Renard::Incunabula::Devel::TestHelper->test_data_directory->child(qw(PDF Adobe pdf_reference_1-7.pdf));
} catch {
	plan skip_all => "$_";
};

plan tests => 2;

subtest "Split sentences in PDF" => sub {
	my $pdf_doc = Renard::Incunabula::Format::PDF::Document->new(
		filename => $pdf_ref_path
	);

	my $tagged = $pdf_doc->get_textual_page( 23 );

	Renard::Incunabula::Language::EN::apply_sentence_offsets_to_blocks( $tagged );
	my @sentences = ();

	$tagged->iter_substr_nooverlap(
		sub {
			my ( $substring, %tags ) = @_;
			if( defined $tags{sentence} ) {
				note "$substring\n=-=";
				push @sentences, $substring;
			}
		},
		only => [ 'sentence' ],
	);

	# even though there is a dot in this sentence, it does not get split
	my $sentence_with_dot = 'It includes the precise documentation of the underlying imaging model from Post-Script along with the PDF-specific features that are combined in version 1.7 of the PDF standard.';
	cmp_deeply
		\@sentences,
		superbagof(
			'Preface',  # heading
			'23',       # page number
			$sentence_with_dot,
		),
		'A block is considered its own sentence';
};

subtest "Get offsets" => sub {
	my @sentences = (
		qq|This is a sentence.|,
		qq|(This is a another.|,
		qq|These are in parentheses.)|,
		qq|Tell me, Mr. Anderson, what good is a phone call if you're unable to speak?|,
		qq|A sentence with too   many    spaces   that    should    be   cleaned.|,
	);

	my $txt = join " ", @sentences;

	my $offsets = Renard::Incunabula::Language::EN::_get_offsets($txt);

	is scalar @$offsets, scalar @sentences, 'Right number of sentences';
	my @got_sentences = map { substr $txt, $_->[0], $_->[1] - $_->[0] } @$offsets;

	is_deeply \@got_sentences, \@sentences, 'Same sentences';
};
