/* Simple example of using SoX libraries
 *
 * Copyright (c) 2007-8 robs@users.sourceforge.net
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 2 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#ifdef NDEBUG /* N.B. assert used with active statements so enable always. */
#undef NDEBUG /* Must undef above assert.h or other that might include it. */
#endif

#include "sox.h"
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>

/*
 * Reads input file, applies vol & flanger effects, stores in output file.
 * E.g. example1 monkey.au monkey.aiff
 */
int main(int argc, char * argv[])
{
  static sox_format_t * in, * out; /* input and output files */
  sox_effects_chain_t * chain;
  sox_effect_t * e;
  char * args[10];

  assert(argc == 3);

  /* All libSoX applications must start by initialising the SoX library */
  assert(sox_init() == SOX_SUCCESS);

  /* Open the input file (with default parameters) */
  assert(in = sox_open_read(argv[1], NULL, NULL, NULL));

  sox_signalinfo_t interm_signal = in->signal; /* NB: deep copy */

  printf("input:\n");
  printf("  rate %f\n", interm_signal.rate);
  printf("  length %d\n", interm_signal.length);
  printf("  mult %f\n", interm_signal.mult == NULL ? -1.2345f : *interm_signal.mult);



  /* Open the output file; we must specify the output signal characteristics.
   * Since we are using only simple effects, they are the same as the input
   * file characteristics */
  assert(out = sox_open_write(argv[2], &interm_signal, &in->encoding, NULL, NULL, NULL));

  printf("output:\n");
  printf("  rate %f\n", out->signal.rate);
  printf("  length %d\n", out->signal.length);
  printf("  mult %f\n", out->signal.mult == NULL ? -1.2345f : *out->signal.mult);

  /* Create an effects chain; some effects need to know about the input
   * or output file encoding so we provide that information here */
  chain = sox_create_effects_chain(&in->encoding, &out->encoding);

  /* The first effect in the effect chain must be something that can source
   * samples; in this case, we use the built-in handler that inputs
   * data from an audio file */
  e = sox_create_effect(sox_find_effect("input"));
  args[0] = (char *)in, assert(sox_effect_options(e, 1, args) == SOX_SUCCESS);
  /* This becomes the first `effect' in the chain */
  assert(sox_add_effect(chain, e, &interm_signal, &out->signal) == SOX_SUCCESS);
  free(e);

  e = sox_create_effect(sox_find_effect("pitch"));
  args[0] = "1200", assert(sox_effect_options(e, 1, args) == SOX_SUCCESS);
  assert(sox_add_effect(chain, e, &interm_signal, &out->signal) == SOX_SUCCESS);
  free(e);

  if (interm_signal.channels != out->signal.channels) {
    e = sox_create_effect(sox_find_effect("channels"));
    assert(sox_effect_options(e, 0, NULL) == SOX_SUCCESS);
    assert(sox_add_effect(chain, e, &interm_signal, &out->signal) == SOX_SUCCESS);
    free(e);
  }
  if (interm_signal.rate != out->signal.rate) {
    e = sox_create_effect(sox_find_effect("rate"));
    assert(sox_effect_options(e, 0, NULL) == SOX_SUCCESS);
    assert(sox_add_effect(chain, e, &interm_signal, &out->signal) == SOX_SUCCESS);
    free(e);
  }


  /* The last effect in the effect chain must be something that only consumes
   * samples; in this case, we use the built-in handler that outputs
   * data to an audio file */
  e = sox_create_effect(sox_find_effect("output"));
  args[0] = (char *)out, assert(sox_effect_options(e, 1, args) == SOX_SUCCESS);
  assert(sox_add_effect(chain, e, &interm_signal, &out->signal) == SOX_SUCCESS);
  free(e);

  printf("before flow:\n");
  printf("  rate %f\n", out->signal.rate);
  printf("  length %d\n", out->signal.length);
  printf("  mult %f\n", out->signal.mult == NULL ? -1.2345f : *out->signal.mult);

  /* Flow samples through the effects processing chain until EOF is reached */
  sox_flow_effects(chain, NULL, NULL);

  printf("output:\n");
  printf("  rate %f\n", out->signal.rate);
  printf("  length %d\n", out->signal.length);
  printf("  mult %f\n", out->signal.mult == NULL ? -1.2345f : *out->signal.mult);

  /* All done; tidy up: */
  sox_delete_effects_chain(chain);
  sox_close(out);
  sox_close(in);
  sox_quit();
  return 0;
}
