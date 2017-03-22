#!/usr/bin/env python
# -*- coding: utf-8
#
# Gibran Fuentes-Pineda <gibranfp@unam.mx>
# IIMAS, UNAM
# 2017
#
# -------------------------------------------------------------------------
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# -------------------------------------------------------------------------
"""
Performs topic discovery using NMF and Online LDA
"""
import argparse
import sys
import os
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer, CountVectorizer
from sklearn.decomposition import NMF, LatentDirichletAllocation
from scipy.sparse import csr_matrix
from sklearn.externals import joblib
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import time
from smh import csr_load_from_listdb_file
from topics import load_vocabulary, save_topics, save_time, array_to_topics

def discover_topics(corpuspath,
                    vocpath,
                    savedir,
                    n_topics = 100,
                    top_terms_numbers = [10]):
    """
    Discovers topics and evaluates model using topic coherence
    """
    print "Loading corpus"
    documents = csr_load_from_listdb_file(corpuspath)

    # LDA model (parameter choice based on )
    model = LatentDirichletAllocation(n_topics = n_topics,
                                      doc_topic_prior = None,
                                      topic_word_prior = None,
                                      learning_method = 'online',
                                      learning_decay = 0.5,
                                      learning_offset = 64,
                                      max_iter = 5,
                                      batch_size = 4096,
                                      evaluate_every = -1,
                                      total_samples = 1e6,
                                      perp_tol = 1e-1,
                                      mean_change_tol = 1e-3,
                                      max_doc_update_iter = 100,
                                      n_jobs = 1,
                                      verbose = 0,
                                      random_state = 1)

    print "Discovering topics using LDA with", n_topics, "topics"
    start_time = time.time()
    model.fit(documents)
    end_time = time.time()
    total_time = end_time - start_time
              
    print "Generating topics (lists of terms) from models"
    topics = array_to_topics(model.components_, vocpath)

    corpusname = os.path.splitext(os.path.basename(corpuspath))[0]
    modelfile = savedir + '/lda' + str(n_topics) + '_' + corpusname + '.models'
    print "Saving resulting models to", modelfile
    np.savetxt(modelfile, model.components_)

    # save topics with different top terms numbers
    for top in top_terms_numbers:
        topicfile = savedir + '/lda' + str(n_topics) + '_' + corpusname + '_top' + str(top) + '.topics'
        print "Saving the top", top, " terms of the topic to", topicfile
        save_topics(topicfile, topics, top = top)

    timefile = savedir + '/lda' + str(n_topics) + '_' + corpusname + '.time'
    print "Saving times to", timefile
    save_time(timefile, total_time)

def main():
    try:
        parser = argparse.ArgumentParser()
        parser = argparse.ArgumentParser(
        description="Evaluates Online LDA in topic discovery")
        parser.set_defaults(fig=False)
        parser.add_argument("corpus", nargs=1, type=str,
                            help="Corpus file (database of ID lists)")
        parser.add_argument("vocabulary", nargs=1, type=str,
                            help="Vocabulary file for corpus")
        parser.add_argument("dir",  nargs=1, type=str,
                            help="Directory where the models, topics and times are to be saved")
        parser.add_argument("-n", "--n_topics", type=int, default=100,
                            help="Number of topics")
        parser.add_argument("-t", "--top", type=int, default=[5, 10, 15, 20], nargs='*',
                            help="Configuration number to try")
        args = parser.parse_args()
        discover_topics(args.corpus[0],
                        args.vocabulary[0],
                        args.dir[0],
                        n_topics = args.n_topics,
                        top_terms_numbers = args.top)
        
    except SystemExit:
        print "for help use --help"
        sys.exit(2)

if __name__ == "__main__":
    main()
