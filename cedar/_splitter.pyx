
from libc.stdlib cimport free
from libc.stdlib cimport malloc
from libc.stdlib cimport realloc
from libc.stdio cimport printf

cimport cython

import numpy as np
cimport numpy as np
np.import_array()

from ._utils cimport get_random
from ._utils cimport compute_gini
from ._utils cimport generate_distribution
from ._utils cimport sample_distribution

cdef class _Splitter:
    """
    Splitter class.
    Finds the best splits on dense data, one split at a time.
    """

    def __cinit__(self, int min_samples_leaf, double lmbda):
        """
        Parameters
        ----------
        min_samples_leaf : int
            The minimal number of samples each leaf can have, where splits
            which would result in having less samples in a leaf are not
            considered.
        lmbda : double
            Noise control when generating distribution; higher values mean a
            more deterministic algorithm.
        """
        self.min_samples_leaf = min_samples_leaf
        self.lmbda = lmbda

    def __dealloc__(self):
        """Destructor."""
        pass

    @cython.boundscheck(False)
    @cython.wraparound(False)
    cdef int node_split(self, int** X, int* y,
                        int* samples, int n_samples,
                        int* features, int n_features,
                        double parent_p, SplitRecord* split) nogil:
        """
        Find the best split in the node data.
        This is a placeholder method. The majority of computation will be done here.
        """

        # parameters
        cdef int min_samples_leaf = self.min_samples_leaf
        cdef double lmbda = self.lmbda

        cdef int i
        cdef int j
        cdef int k
        cdef int chosen_ndx
        cdef int chosen_feature

        cdef int count = n_samples
        cdef int pos_count = 0
        cdef int left_count
        cdef int left_pos_count
        cdef int right_count
        cdef int right_pos_count

        cdef int feature_count = 0
        cdef int result = 0

        cdef double* gini_indices = NULL
        cdef double* distribution = NULL
        cdef int* valid_features = NULL

        cdef int* left_counts = NULL
        cdef int* left_pos_counts = NULL
        cdef int* right_counts = NULL
        cdef int* right_pos_counts = NULL

        # count number of pos labels
        for i in range(n_samples):
            if y[samples[i]] == 1:
                pos_count += 1

        if pos_count > 0 and pos_count < count:

            gini_indices = <double *>malloc(n_features * sizeof(double))
            distribution = <double *>malloc(n_features * sizeof(double))
            valid_features = <int *>malloc(n_features * sizeof(int))

            left_counts = <int *>malloc(n_features * sizeof(int))
            left_pos_counts = <int *>malloc(n_features * sizeof(int))
            right_counts = <int *>malloc(n_features * sizeof(int))
            right_pos_counts = <int *>malloc(n_features * sizeof(int))

            # compute statistics for each attribute
            for j in range(n_features):

                left_count = 0
                left_pos_count = 0

                for i in range(n_samples):

                    if X[samples[i]][features[j]] == 1:
                        left_count += 1
                        left_pos_count += y[samples[i]]

                right_count = count - left_count
                right_pos_count = pos_count - left_pos_count

                # validate split
                if left_count >= min_samples_leaf and right_count >= min_samples_leaf:
                    valid_features[feature_count] = features[j]
                    gini_indices[feature_count] = compute_gini(count, left_count, right_count,
                                                               left_pos_count, right_pos_count)

                    # save metadata
                    left_counts[feature_count] = left_count
                    left_pos_counts[feature_count] = left_pos_count
                    right_counts[feature_count] = right_count
                    right_pos_counts[feature_count] = right_pos_count

                    feature_count += 1

            if feature_count > 0:

                # remove invalid features
                gini_indices = <double *>realloc(gini_indices, feature_count * sizeof(double))
                distribution = <double *>realloc(distribution, feature_count * sizeof(double))
                valid_features = <int *>realloc(valid_features, feature_count * sizeof(int))

                left_counts = <int *>realloc(left_counts, feature_count * sizeof(int))
                left_pos_counts = <int *>realloc(left_pos_counts, feature_count * sizeof(int))
                right_counts = <int *>realloc(right_counts, feature_count * sizeof(int))
                right_pos_counts = <int *>realloc(right_pos_counts, feature_count * sizeof(int))

                # generate and sample from the distribution
                generate_distribution(lmbda, distribution, gini_indices, feature_count)
                chosen_ndx = sample_distribution(distribution, feature_count)

                # assign results from chosen feature
                split.left_indices = <int *>malloc(left_counts[chosen_ndx] * sizeof(int))
                split.right_indices = <int *>malloc(right_counts[chosen_ndx] * sizeof(int))
                j = 0
                k = 0
                for i in range(n_samples):
                    if X[samples[i]][valid_features[chosen_ndx]] == 1:
                        split.left_indices[j] = samples[i]
                        j += 1
                    else:
                        split.right_indices[k] = samples[i]
                        k += 1
                split.left_count = j
                split.right_count = k
                split.feature = valid_features[chosen_ndx]

                split.p = parent_p * distribution[chosen_ndx]
                split.count = count
                split.pos_count = pos_count

                split.feature_count = feature_count
                split.valid_features = valid_features
                split.left_counts = left_counts
                split.left_pos_counts = left_pos_counts
                split.right_counts = right_counts
                split.right_pos_counts = right_pos_counts

                free(gini_indices)
                free(distribution)

            else:
                result = -1
                free(gini_indices)
                free(distribution)
                free(valid_features)

                free(left_counts)
                free(left_pos_counts)
                free(right_counts)
                free(right_pos_counts)

        else:
            result = -1

        return result