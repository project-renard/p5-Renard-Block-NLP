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

plan tests => 1;

subtest "Split sentences" => sub {
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
